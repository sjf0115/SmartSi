---
layout: post
author: sjf0115
title: Flink1.4 事件时间与处理时间
date: 2018-01-04 16:47:01
tags:
  - Flink

categories: Flink
---


`Flink`在数据流中支持几种不同概念的时间。

### 1. 处理时间

`Processing Time`(处理时间)是指执行相应操作机器的系统时间(Processing time refers to the system time of the machine that is executing the respective operation.)。

当一个流程序以处理时间来运行时，所有基于时间的操作(如时间窗口)将使用运行算子(`operator`)所在机器的系统时间。例如:一个基于处理时间按每小时进行处理的时间窗口将包括以系统时间为标准在一个小时内到达指定算子的所有的记录(an hourly processing time window will include all records that arrived at a specific operator between the times when the system clock indicated the full hour.)。

处理时间是最简单的一个时间概念，不需要在数据流和机器之间进行协调。它有最好的性能和最低的延迟。然而，在分布式或者异步环境中，处理时间具有不确定性，因为容易受到记录到达系统速度的影响(例如从消息队列到达的记录)，还会受到系统内记录流在不同算子之间的流动速度的影响(speed at which records arrive in the system, and to the speed at which the records flow between operators inside the system)。

### 2. 事件时间

`Event Time`(事件时间)是每个独立事件在它生产设备上产生的时间。在进入`Flink`之前，事件时间通常要嵌入到记录中，并且事件时间也可以从记录中提取出来。一个基于事件时间按每小时进行处理的时间窗口将包含所有的记录，其事件时间都在这一小时之内，不管它们何时到达，以及它们以什么顺序到达。

事件时间即使在乱序事件，延迟事件以及从备份或持久化日志中的重复数据也能获得正确的结果。对于事件时间，时间的进度取决于数据，而不是任何时钟。事件时间程序必须指定如何生成事件时间的`Watermarks`，这是表示事件时间进度的机制。

按事件时间处理往往会导致一定的延迟，因为它要等待延迟事件和无序事件一段时间。因此，事件时间程序通常与处理时间操作相结合使用。

### 3. 摄入时间

`Ingestion Time`(摄入时间)是事件进入`Flink`的时间。在`source operator`中，每个记录将源的当前时间记为时间戳，基于时间的操作(如时间窗口)会使用该时间戳。

摄入时间在概念上处于事件时间和处理时间之间。与处理时间相比，摄入时间的成本稍微更高一些，但是可以提供更可预测的结果。因为摄入时间的时间戳比较稳定(在源处只记录一次)，同一数据在流经不同窗口操作时将使用相同的时间戳，然而对于处理时间，每个窗口算子可能将记录分配给不同的窗口(基于本地系统时钟以及传输延迟)。

与事件时间相比，摄入时间程序无法处理任何无序事件或延迟事件，但程序不必指定如何生成`watermarks`。

在内部，摄入时间与事件时间非常相似，但事件时间会自动分配时间戳以及自动生成`watermark`(with automatic timestamp assignment and automatic watermark generation)。

![](https://github.com/sjf0115/PubLearnNotes/blob/master/image/Flink/Flink1.4%20%E4%BA%8B%E4%BB%B6%E6%97%B6%E9%97%B4%E4%B8%8E%E5%A4%84%E7%90%86%E6%97%B6%E9%97%B4.png?raw=true)

### 4. 选择时间特性

`Flink DataStream`程序的第一部分通常设置基本的时间特性(base time characteristic)。该设置定义数据流源的行为方式(例如，它们是否产生时间戳)，以及窗口操作如`KeyedStream.timeWindow(Time.seconds(30))`应使用哪一类型时间，是事件时间还是处理时间等。

以下示例展示了一个聚合每小时时间窗口内的事件的`Flink`程序。窗口的行为会与时间特性相匹配。

Java版本:
```java
final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

env.setStreamTimeCharacteristic(TimeCharacteristic.ProcessingTime);

// alternatively:
// env.setStreamTimeCharacteristic(TimeCharacteristic.IngestionTime);
// env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime);

DataStream<MyEvent> stream = env.addSource(new FlinkKafkaConsumer09<MyEvent>(topic, schema, props));

stream
    .keyBy( (event) -> event.getUser() )
    .timeWindow(Time.hours(1))
    .reduce( (a, b) -> a.add(b) )
    .addSink(...);
```
Scala版本:
```
val env = StreamExecutionEnvironment.getExecutionEnvironment

env.setStreamTimeCharacteristic(TimeCharacteristic.ProcessingTime)

// alternatively:
// env.setStreamTimeCharacteristic(TimeCharacteristic.IngestionTime)
// env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

val stream: DataStream[MyEvent] = env.addSource(new FlinkKafkaConsumer09[MyEvent](topic, schema, props))

stream
    .keyBy( _.getUser )
    .timeWindow(Time.hours(1))
    .reduce( (a, b) => a.add(b) )
    .addSink(...)
```

备注:
```
为了以事件时间运行此示例，程序需要使用定义了事件时间并自动产生watermarks的源，或者程序必须在源之后设置时间戳分配器和watermarks生成器。上述函数描述了如何获取事件时间戳，以及展现事件流的无序程度。
```

备注:
```
Flink版本:1.4
```

原文:https://ci.apache.org/projects/flink/flink-docs-release-1.4/dev/event_time.html#event-time--processing-time--ingestion-time
