---
layout: post
author: sjf0115
title: Flink1.4 检查点启用与配置
date: 2018-01-17 12:30:17
tags:
  - Flink
  - Flink 容错

categories: Flink
permalink: flink-stream-development-checkpointing-enable-config
---

Flink 中的每个函数和操作符都可以是有状态的（请参阅[使用状态](http://smartsi.club/2018/01/16/flink-stream-working-with-state/)了解详细信息）。有状态函数在处理单个元素/事件时存储数据。

为了能够状态容错，Flink 需要对状态进行 `checkpoint`。检查点允许 `Flink` 在流中恢复状态和位置，为应用程序提供与无故障执行相同的语义。

关于 Flink 流式容错机制背后的技术请参阅[流式容错](http://smartsi.club/2018/01/24/flink-data-streaming-fault-tolerance/)的详细文档。

### 1. 前提条件

`Flink` 的检查点机制与流和状态的持久存储进行交互。一般来说，它要求：
- 一个可持久化（或保存很长时间）的数据源，可以重放特定时间段的记录。持久消息队列是这种数据源的一个例子（例如 `Apache Kafka`，`RabbitMQ`，`Amazon Kinesis`，`Google PubSub`）或 文件系统（例如 `HDFS`， `S3`， `GFS`， `NFS`， `Ceph` 等）。
- 状态的持久化存储，通常是分布式文件系统（例如 `HDFS`， `S3`， `GFS`， `NFS`， `Ceph` 等）

### 2. 启用和配置检查点

默认情况下，检查点被禁用。要启用检查点，要在 `StreamExecutionEnvironment` 上调用 `enableCheckpointing（n）`，其中`n`是检查点时间间隔（以毫秒为单位）。

检查点的其他参数包括：

(1)  `exactly-once` 与 `at-least-once`：你可以选择性的将模式传递给 `enableCheckpointing（n）` 方法来在两个保证级别之间进行选择。对于大多数应用来说，一般都选择 `exactly-once`。`at-least-once`可能与某些超低延迟（持续几毫秒）的应用程序有关。

(2) 检查点超时：如果在规定时间之前没有完成检查点，正在进行的检查点就会被终止。

(3) 检查点之间的最小时间：为了确保流式应用程序在检查点之间有一定的进展，可以定义检查点之间的时间间隔。例如，如果此值设置为5000，不论检查点持续时间和检查点间隔是多少，下一个检查点将在上一个检查点完成之后的5秒内启动。请注意，这意味着检查点间隔 `checkpoint interval` 永远不会小于此参数。

通过定义 `检查点之间的时间差` (`time between checkpoints`)而不是检查点间隔(`checkpoint interval`)来配置应用程序通常更容易，因为 `检查点之间的时间差` 不会受到检查点有时花费比平均时间更长时间的影响（例如，如果目标存储系统暂时比较慢）。

请注意，这个值也意味着并发检查点的数量为1。

(4) 并发检查点的数量：默认情况下，当一个检查点正在运行时，系统不会触发另一个检查点。这确保了拓扑结构不会在检查点上花费太多时间，并且不会在处理流时有进展(not make progress with processing the streams)。可以允许多个重叠的检查点，这对于具有一定处理延迟（例如，因为函数调用外部服务需要等待一些时间响应），但是仍然想要做非常频繁的 `checkpoints`（100毫秒 ）重新处理很少见的失败情况具有一定意义。

定义检查点之间的最短时间时，不能使用此选项。

(5) 外部检查点`externalized checkpoints`：可以配置定期检查点持久化到从外部存储中。外部检查点将其元数据写入持久性存储，作业失败时也不会自动清理。这样，如果你的作业失败，你将会有一个检查点用来恢复。有关[外部检查点](http://smartsi.club/2018/01/30/flink-stream-deployment-externalized-checkpoints/)的部署说明中有更多详细信息。

Java版本:
```Java
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

// start a checkpoint every 1000 ms
env.enableCheckpointing(1000);

// advanced options:

// set mode to exactly-once (this is the default)
env.getCheckpointConfig().setCheckpointingMode(CheckpointingMode.EXACTLY_ONCE);

// make sure 500 ms of progress happen between checkpoints
env.getCheckpointConfig().setMinPauseBetweenCheckpoints(500);

// checkpoints have to complete within one minute, or are discarded
env.getCheckpointConfig().setCheckpointTimeout(60000);

// allow only one checkpoint to be in progress at the same time
env.getCheckpointConfig().setMaxConcurrentCheckpoints(1);

// enable externalized checkpoints which are retained after job cancellation
env.getCheckpointConfig().enableExternalizedCheckpoints(ExternalizedCheckpointCleanup.RETAIN_ON_CANCELLATION);
```
Scala版本:
```scala
val env = StreamExecutionEnvironment.getExecutionEnvironment()

// start a checkpoint every 1000 ms
env.enableCheckpointing(1000)

// advanced options:

// set mode to exactly-once (this is the default)
env.getCheckpointConfig.setCheckpointingMode(CheckpointingMode.EXACTLY_ONCE)

// make sure 500 ms of progress happen between checkpoints
env.getCheckpointConfig.setMinPauseBetweenCheckpoints(500)

// checkpoints have to complete within one minute, or are discarded
env.getCheckpointConfig.setCheckpointTimeout(60000)

// allow only one checkpoint to be in progress at the same time
env.getCheckpointConfig.setMaxConcurrentCheckpoints(1)
```

### 3. 相关配置选项

其他参数和默认值也可以通过`conf/flink-conf.yaml`配置文件进行设置（请参阅完整指南的[配置](https://ci.apache.org/projects/flink/flink-docs-release-1.4/ops/config.html)）：

(1) `state.backend`：如果启用了检查点，用来存储算子状态检查点的终端。支持的终端：
- `jobmanager`：内存状态，备份到 `JobManager`/`ZooKeeper` 的内存中。应在较小状态（`Kafka`偏移量）或测试和本地调试时使用。
- 文件系统：状态存储在 `TaskManager` 的内存中，状态快照存储在文件系统中。`Flink`支持所有文件系统，例如 `HDFS`，`S3`，...

(2) `state.backend.fs.checkpointdir`：用于在 `Flink` 支持的文件系统中存储检查点的目录。注意：`JobManager` 必须可以访问状态终端，本地安装时可以使用`file：//`。

(3) `state.backend.rocksdb.checkpointdir`: 用于存储 `RocksDB` 文件的本地目录，或由系统目录分隔符（例如`Linux/Unix`上的'：'（冒号））分隔的目录列表。（默认值是`taskmanager.tmp.dirs`）

(4) `state.checkpoints.dir`: 外部检查点元数据的目标目录。

(5) `state.checkpoints.num-retained`: 已完成的检查点实例的数量。如果最新的检查点已损坏，必须使用多个实例才可以恢复回退到较早的检查点。（默认值：1）

### 4. 选择状态终端

`Flink` 的[检查点机制](http://smartsi.club/2018/01/24/flink-data-streaming-fault-tolerance/)存储定时器中所有状态和有状态算子的一致性快照，包括连接器，窗口以及任何用户自定义的状态。检查点存储的位置（例如，`JobManager` 的内存，文件系统，数据库）取决于状态终端的配置。

默认情况下，状态保存在 `TaskManager` 的内存中，检查点存储在 `JobManager` 的内存中。为了适当地存储较大的状态，`Flink` 也支持多种方法在其他状态终端存储状态以及对状态进行检查点操作。状态终端的选择可以通过 `StreamExecutionEnvironment.setStateBackend（...）` 来配置。

有关可用状态终端以及作业范围和群集范围内配置选项的的详细信息，请参阅[状态终端](http://smartsi.club/2018/01/17/flink-stream-state-backends/)。

### 5. 迭代作业中的状态检查点

目前 `Flink` 只为无迭代作业提供处理保证。在迭代作业上启用检查点会导致异常。为了在迭代程序上强制进行检查点操作，用户需要在启用检查点时设置特殊标志：`env.enableCheckpointing（interval，force = true）`。

### 6. 重启策略

Flink支持不同的重启策略，控制在失败情况下重启的方式。有关更多信息，请参阅[重启策略](http://smartsi.club/2018/01/04/flink-restart-strategy/)。

> 备注:

> Flink版本:1.4

原文:https://ci.apache.org/projects/flink/flink-docs-release-1.4/dev/stream/state/checkpointing.html
