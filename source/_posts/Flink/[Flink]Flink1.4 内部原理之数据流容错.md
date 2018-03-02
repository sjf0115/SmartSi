---
layout: post
author: sjf0115
title: Flink1.4 内部原理之数据流容错
date: 2018-01-24 14:39:01
tags:
  - Flink
  - Flink 内部原理

categories: Flink
permalink: flink-data-streaming-fault-tolerance
---

### 1. 概述

`Apache Flink`提供了一个容错机制来持续恢复数据流应用程序的状态。该机制确保即使在出现故障的情况下，程序的状态也将最终反映每条记录来自数据流严格一次`exactly once`。 请注意，有一个开关可以降级为保证至少一次(`least once`)（如下所述）。

容错机制连续生成分布式流数据流的快照。对于状态较小的流式应用程序，这些快照非常轻量级，可以频繁生成，而不会对性能造成太大影响。流应用程序的状态存储在可配置的位置（例如主节点或`HDFS`）。

如果应用程序发生故障（由于机器，网络或软件故障），`Flink`会停止分布式流式数据流。然后系统重新启动算子并将其重置为最新的成功检查点。输入流被重置为状态快照的时间点。作为重新启动的并行数据流处理的任何记录都保证不属于先前检查点状态的一部分。

注意:默认情况下，检查点被禁用。有关如何启用和配置检查点的详细信息，请参[阅检查点](http://smartsi.club/2018/01/17/flink-stream-development-checkpointing-enable-config/)。

为了实现这个机制的保证，数据流源（如消息队列或代理）需要能够将流重放到定义的最近时间点。`Apache Kafka`有这个能力，而`Flink`的Kafka连接器就是利用这个能力。有关`Flink`连接器提供的保证的更多信息，请参阅[数据源和接收器的容错保证](https://ci.apache.org/projects/flink/flink-docs-release-1.4/dev/connectors/guarantees.html)。

因为`Flink`的检查点是通过分布式快照实现的，所以我们交替使用`快照`和`检查点`两个概念。

### 2. Checkpointing

`Flink`的容错机制的核心部分是生成分布式数据流和算子状态的一致性快照。这些快照作为一个一致性检查点，在系统发生故障时可以回溯。`Flink`的生成这些快照的机制在[分布式数据流的轻量级异步快照](https://arxiv.org/abs/1506.08603)中进行详细的描述。它受分布式快照`Chandy-Lamport`算法的启发，并且专门针对`Flink`的执行模型量身定制。

#### 2.1 Barriers

`Flink`分布式快照的一个核心元素是数据流`Barriers`。这些`Barriers`被放入数据流中，并作为数据流的一部分与记录一起流动。`Barriers`永远不会超越记录，严格按照相对顺序流动。`Barriers`将数据流中的记录分成进入当前快照的记录集合和进入下一个快照的记录集合。每个`Barriers`都携带前面快照的ID。`Barriers`不会中断流的流动，因此非常轻。来自不同快照的多个`Barriers`可以同时在流中，这意味着不同快照可以同时发生。

![](https://github.com/sjf0115/PubLearnNotes/blob/master/image/Flink/%E5%86%85%E9%83%A8%E5%8E%9F%E7%90%86%E4%B9%8B%E6%95%B0%E6%8D%AE%E6%B5%81%E5%AE%B9%E9%94%99-1.png?raw=true)

`Barriers`在数据流源处被放入的并行数据流。快照`n`放入`Barriers`的位置（我们称之为`Sn`）是快照覆盖数据的源流中的位置。例如，在`Apache Kafka`中，这个位置是分区中最后一个记录的偏移量。该位置`Sn`会报告给检查点协调员（`Flink`的`JobManager`）。

`Barriers`向下游流动。当中间算子从其所有输入流中接收到快照`n`的`Barriers`时，它会将快照`n`的`Barriers`发送到其所有输出流中。一旦`Sink`算子（流式`DAG`的末尾）从其所有输入流中接收到`Barriers n`，就向检查点协调器确认快照`n`。在所有`Sink`确认了快照之后，才被确认已经完成。

一旦快照`n`完成，作业将不会再向数据源询问`Sn`之前的记录，因为那时这些记录（以及它们的后代记录）已经通过了整个数据流拓扑。

![](https://github.com/sjf0115/PubLearnNotes/blob/master/image/Flink/%E5%86%85%E9%83%A8%E5%8E%9F%E7%90%86%E4%B9%8B%E6%95%B0%E6%8D%AE%E6%B5%81%E5%AE%B9%E9%94%99-2.png?raw=true)

接收多个输入流的算子需要根据快照`Barriers`对其输入流。上图说明了这一点：
- 只要算子从一个输入流接收到快照`Barriers n`时，就不能处理来自该数据流的任何记录(译者注:进行缓存)，当从其他输入流中接收到最后一个`Barriers n`时，才开始处理缓存的数据(即对齐的意思)。否则，就会混合属于快照`n`和快照`n + 1`的记录。
- 报告`Barriers n`的数据流暂时搁置。从这些数据流接收到的记录不会被处理，而是放入输入缓冲区中(例如上图中的`aligning`部分)。
- 一旦接收到最后一个流的`Barriers n`时，算子才发送所有待发送的记录，然后才发送快照`Barriers n`自己(例如上图中的`checkpoint`部分)。
- 之后，恢复处理所有输入流中的记录，在处理来自数据流的记录之前优先处理来自输入缓冲区中的记录(例如上图中的`continue`部分)。

#### 2.2 State

当算子包含任何形式的状态时，这个状态也必须是快照的一部分。算子状态有不同的形式：
- 用户自定义状态：这是由转换函数（如`map（）`或`filter（）`）直接创建和修改的状态。有关详细信息，请参阅[状态概述](http://smartsi.club/2018/01/16/flink-stream-state-overview/)
- 系统状态：这种状态指的是作为算子计算一部分的数据缓冲区。这种状态的一个典型例子是窗口缓冲区，在窗口缓冲区中，系统为窗口收集（以及聚合）记录，直到窗口被计算和删除。

在算子收到所有输入流中的所有快照`barriers`以及在`barriers`发送到输出流之前，算子对自己的状态进行快照。这时，At that point, all updates to the state from records before the barriers will have been made, and no updates that depend on records from after the barriers have been applied。由于快照的状态可能较大，因此需要其存储在可配置状态终端`state backend`中。默认情况下，会存储在`JobManager`的内存中，但是在生产环境下，应该配置为分布式可靠存储系统（如`HDFS`）。在状态被存储之后，算子确认检查点，将快照`barriers`发送到输出流，然后继续前行。

生成的快照包含：
- 对于每个并行流数据源，快照启动时在数据流中的偏移量/位置
- 对于每个算子，指向作为快照中一部分的状态的指针

![](https://github.com/sjf0115/PubLearnNotes/blob/master/image/Flink/%E5%86%85%E9%83%A8%E5%8E%9F%E7%90%86%E4%B9%8B%E6%95%B0%E6%8D%AE%E6%B5%81%E5%AE%B9%E9%94%99-3.png?raw=true)

#### 2.3 Exactly Once vs. At Least Once

对齐步骤可能会给流式传输程序造成延迟。这个额外的延迟通常大约在几毫秒的数量级，但是我们已经看到一些因为异常值造成的延迟明显增加的情况。对于所有记录需要持续较低延迟（几毫秒）的应用程序而言，`Flink`有一个开关可以在检查点期间跳过流对齐。一旦算子看到每个输入的检查点`barriers`，就会生成检查点快照。

当跳过对齐步骤时，即使在检查点`n`的一些检查点`barriers`到达之后，算子也会继续处理所有输入。这样，在为检查点`n`生成状态快照之前也会处理到属于检查点`n+1`的元素。在恢复时，这些记录将会重复出现，因为它们既包含在检查点`n`的状态快照中，也会在检查点`n`之后作为数据的一部分进行重放。

备注:

对齐仅发生在当算子具有多个输入（例如`join`）或者具有多个输出（在流`repartitioning`/`shuffle`之后）的情况。正因为如此，只有密集并行流操作(only embarrassingly parallel streaming operations)（`map（）`，`flatMap（）`，`filter（）`...）的数据流即使在至少一次模式下也只能提供严格一次。

#### 2.4 异步状态快照

请注意，上述机制意味着算子在状态终端存储状态快照时停止处理输入记录。这种同步状态快照在每次生成快照时都会造成延迟。

可以让算子在存储其状态快照的同时继续处理输入记录，有效地让状态快照在后台异步发生。要做到这一点，算子必须能够产生一个以某种方式存储的状态对象，以至于对算子状态的进一步的修改不会影响状态对象。例如，`copy-on-write`数据结构（如`RocksDB`中使用的数据结构）具有这种功能。

在接收到输入端的检查点`barriers`后，算子启动其状态的异步快照复制。`barriers`立即发送到输出流中，并继续进行正常的流处理。一旦后台复制过程完成，它就会向检查点协调器（JobManager）确认检查点。检查点现在只有在所有`sink`接收到`barriers`并且所有有状态的算子已经确认完成备份（可能在`barriers`到达`sink`之后）。

有关状态快照的详细信息，请参阅[状态终端](http://smartsi.club/2018/01/17/flink-stream-state-backends/)。

### 3. 恢复

在这种机制下恢复很简单：一旦失败，`Flink`选择最近完成的检查点`k`。然后系统重新部署整个分布式数据流，并为每个算子提供作为检查点`k`一部分的快照状态。数据源被设置为开始从位置`Sk`读取数据流。例如在`Apache Kafka`中，这意味着告诉消费者从偏移量`Sk`处开始提取数据。

如果增量对状态进行快照，算子将从最新且完整的快照状态开始，然后对该状态应用一系列增量快照更新。

请参阅[重启策略](http://smartsi.club/2018/01/04/flink-restart-strategy/)了解更多信息。

### 4. 实现算子快照

对算子进行快照，有两部分：同步部分和异步部分。

算子和状态终端将其快照作为`Java FutureTask`。该任务包含的状态同步部分已经完成异步部分挂起。然后异步部分由该检查点的后台线程执行。

算子检查点只是同步返回一个已经完成的`FutureTask`。如果需要执行异步操作，则在`FutureTask的run（）`方法中执行。

任务是可取消的，所以消耗句柄的数据流和其他资源是可以被释放。

原文:https://ci.apache.org/projects/flink/flink-docs-release-1.4/internals/stream_checkpointing.html
