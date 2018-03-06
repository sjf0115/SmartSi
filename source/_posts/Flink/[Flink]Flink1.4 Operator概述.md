---
layout: post
author: sjf0115
title: Flink1.4 Operator概述
date: 2018-02-28 10:25:17
tags:
  - Flink
  - Flink Stream

categories: Flink
permalink: flink-stream-operators-overall
---

算子(`Operator`)将一个或多个 `DataStream` 转换为新的 `DataStream`。程序可以将多个转换组合成复杂的数据流拓扑。

本节将介绍基本转换(`transformations`)操作，应用这些转换后的有效物理分区以及深入了解 Flink 算子链。

### 1. DataStream Transformations

#### 1.1 Map  

```
DataStream → DataStream
```

输入一个元素并生成一个对应的元素。下面是一个将输入流的值加倍的 `map` 函数：

Java版本：
```Java
DataStream<Integer> dataStream = //...
dataStream.map(new MapFunction<Integer, Integer>() {
    @Override
    public Integer map(Integer value) throws Exception {
        return 2 * value;
    }
});
```

scala版本：
```scala
dataStream.map { x => x * 2 }
```

#### 1.2 FlatMap

```
DataStream → DataStream
```
输入一个元素并生成零个，一个或多个元素。下面是个将句子拆分为单词的 `flatMap` 函数：

Java版本：
```java
dataStream.flatMap(new FlatMapFunction<String, String>() {
    @Override
    public void flatMap(String value, Collector<String> out)
        throws Exception {
        for(String word: value.split(" ")){
            out.collect(word);
        }
    }
});
```
Scala版本:
```scala
dataStream.flatMap { str => str.split(" ") }
```

#### 1.3 Filter
```
DataStream → DataStream
```
为每个元素计算一个布尔值的函数并保留函数返回 `true` 的那些元素。下面是一个筛选出零值的 `filter` 函数：

Java版本:
```java
dataStream.filter(new FilterFunction<Integer>() {
    @Override
    public boolean filter(Integer value) throws Exception {
        return value != 0;
    }
});
```
Scala版本:
```scala
dataStream.filter { _ != 0 }
```

#### 1.4 KeyBy
```
DataStream → KeyedStream
```
逻辑上将一个流分成不相交的分区，每个分区包含相同键的元素。在内部，这是通过哈希分区实现的。参阅博文[Flink1.4 定义keys的几种方法](http://smartsi.club/2018/01/04/flink-how-to-specifying-keys/)来了解如何指定键。这个转换返回一个 `KeyedStream`。

Java版本:
```java
dataStream.keyBy("someKey") // Key by field "someKey"
dataStream.keyBy(0) // Key by the first element of a Tuple
```

Scala版本:
```scala
dataStream.keyBy("someKey") // Key by field "someKey"
dataStream.keyBy(0) // Key by the first element of a Tuple
```

> 备注

> 在以下情况，不能指定为key：
> - POJO类型，但没有覆盖hashCode()方法并依赖于Object.hashCode()实现。
> - 任意类型的数组。

#### 1.5 Reduce
```
KeyedStream → DataStream
```

键控数据流的"滚动" `reduce`。将当前元素与上一个 `reduce` 后的值组合，并生成一个新值。下面是一个创建局部求和流的 `reduce` 函数：

Java版本:
```java
keyedStream.reduce(new ReduceFunction<Integer>() {
    @Override
    public Integer reduce(Integer value1, Integer value2)
    throws Exception {
        return value1 + value2;
    }
});
```
Scala版本:
```scala
keyedStream.reduce { _ + _ }
```

#### 1.6 Fold
```
KeyedStream → DataStream
```
在具有初始值的键控数据流上"滚动" `fold`。将当前元素与上一个 `fold` 后的值组合，并生成一个新值。下面是 `fold` 函数在在序列（1,2,3,4,5）的演示，生成序列 "start-1"，"start-1-2"，"start-1-2-3"，... :

Java版本:
```java
DataStream<String> result =
  keyedStream.fold("start", new FoldFunction<Integer, String>() {
    @Override
    public String fold(String current, Integer value) {
        return current + "-" + value;
    }
  });
```

Scala版本:
```scala
val result: DataStream[String] =
    keyedStream.fold("start")((str, i) => { str + "-" + i })
```

#### 1.7 Aggregations  
```
KeyedStream → DataStream
```
在键控数据流上滚动聚合。`min` 和 `minBy` 之间的差别是 `min` 返回最小值，而 `minBy` 返回在该字段上具有最小值的元素（`max` 和 `maxBy` 相同）。

Java版本:
```java
keyedStream.sum(0);
keyedStream.sum("key");
keyedStream.min(0);
keyedStream.min("key");
keyedStream.max(0);
keyedStream.max("key");
keyedStream.minBy(0);
keyedStream.minBy("key");
keyedStream.maxBy(0);
keyedStream.maxBy("key");
```
Scala版本:
```scala
keyedStream.sum(0)
keyedStream.sum("key")
keyedStream.min(0)
keyedStream.min("key")
keyedStream.max(0)
keyedStream.max("key")
keyedStream.minBy(0)
keyedStream.minBy("key")
keyedStream.maxBy(0)
keyedStream.maxBy("key")
```

#### 1.8 Window
```
KeyedStream → WindowedStream
```
可以在已分区的 `KeyedStream` 上定义窗口。窗口根据某些特性（例如，在最近5秒内到达的数据）对每个键的数据进行分组。请参阅[窗口](https://ci.apache.org/projects/flink/flink-docs-release-1.4/dev/stream/operators/windows.html)以获取窗口的详细说明。

Java版本:
```java
dataStream.keyBy(0).window(TumblingEventTimeWindows.of(Time.seconds(5))); // Last 5 seconds of data
```
Scala版本:
```scala
dataStream.keyBy(0).window(TumblingEventTimeWindows.of(Time.seconds(5))) // Last 5 seconds of data
```

#### 1.9 WindowAll
```
DataStream → AllWindowedStream
```
可以在常规的 `DataStream` 上定义窗口。窗口根据某些特征（例如，在最近5秒内到达的数据）对所有流事件进行分组。请参阅[窗口](https://ci.apache.org/projects/flink/flink-docs-release-1.4/dev/stream/operators/windows.html)以获取窗口的详细说明。

> 警告

> 在很多情况下是非并行转换。所有记录将被收集到windowAll算子的一个任务中。

Java版本:
```java
dataStream.windowAll(TumblingEventTimeWindows.of(Time.seconds(5))); // Last 5 seconds of data
```
Scala版本:
```scala
dataStream.windowAll(TumblingEventTimeWindows.of(Time.seconds(5))) // Last 5 seconds of data
```

#### 1.10 Window Apply
```
WindowedStream → DataStream
AllWindowedStream → DataStream
```

将常规函数应用于整个窗口。以下是手动对窗口元素求和的函数。

> 注意

> 如果你使用的是windowAll转换，则需要使用AllWindowFunction。

Java版本：
```java
windowedStream.apply (new WindowFunction<Tuple2<String,Integer>, Integer, Tuple, Window>() {
    public void apply (Tuple tuple,
            Window window,
            Iterable<Tuple2<String, Integer>> values,
            Collector<Integer> out) throws Exception {
        int sum = 0;
        for (value t: values) {
            sum += t.f1;
        }
        out.collect (new Integer(sum));
    }
});

// applying an AllWindowFunction on non-keyed window stream
allWindowedStream.apply (new AllWindowFunction<Tuple2<String,Integer>, Integer, Window>() {
    public void apply (Window window,
            Iterable<Tuple2<String, Integer>> values,
            Collector<Integer> out) throws Exception {
        int sum = 0;
        for (value t: values) {
            sum += t.f1;
        }
        out.collect (new Integer(sum));
    }
});
```
Scala版本:
```scala
windowedStream.apply { WindowFunction }

// applying an AllWindowFunction on non-keyed window stream
allWindowedStream.apply { AllWindowFunction }
```

#### 1.11 Window Reduce
```
WindowedStream → DataStream
```
在窗口中应用功能性 `reduce` 函数并返回 `reduce` 后的值。

Java版本:
```java
windowedStream.reduce (new ReduceFunction<Tuple2<String,Integer>>() {
    public Tuple2<String, Integer> reduce(Tuple2<String, Integer> value1, Tuple2<String, Integer> value2) throws Exception {
        return new Tuple2<String,Integer>(value1.f0, value1.f1 + value2.f1);
    }
});
```
Scala版本:
```scala
windowedStream.reduce { _ + _ }
```

#### 1.12 Window Fold
```
WindowedStream → DataStream
```
将功能性 `fold` 函数应用于窗口并返回 `fold` 后值。例如，应用于序列（1,2,3,4,5）时，将序列 `fold` 为字符串 `start-1-2-3-4-5`：

Java版本:
```java
windowedStream.fold("start", new FoldFunction<Integer, String>() {
    public String fold(String current, Integer value) {
        return current + "-" + value;
    }
});
```
Scala版本:
```scala
val result: DataStream[String] =
    windowedStream.fold("start", (str, i) => { str + "-" + i })
```

#### 1.13 Aggregations on windows
```
WindowedStream → DataStream
```
聚合一个窗口的内容。`min` 和 `minBy` 之间的差别是 `min` 返回最小值，而 `minBy` 返回该字段中具有最小值的元素（`max` 和 `maxBy` 相同）。

Java版本:
```java
windowedStream.sum(0);
windowedStream.sum("key");
windowedStream.min(0);
windowedStream.min("key");
windowedStream.max(0);
windowedStream.max("key");
windowedStream.minBy(0);
windowedStream.minBy("key");
windowedStream.maxBy(0);
windowedStream.maxBy("key");
```
Scala版本:
```scala
windowedStream.sum(0)
windowedStream.sum("key")
windowedStream.min(0)
windowedStream.min("key")
windowedStream.max(0)
windowedStream.max("key")
windowedStream.minBy(0)
windowedStream.minBy("key")
windowedStream.maxBy(0)
windowedStream.maxBy("key")
```
#### 1.14 Union
```
DataStream* → DataStream
```
合并两个或更多数据流，创建一个包含所有流中所有元素的新流。

> 注意

> 如果你与自己进行合并，你将在结果流中获取每个元素两次。

Java版本:
```java
dataStream.union(otherStream1, otherStream2, ...);
```
Scala版本:
```scala
dataStream.union(otherStream1, otherStream2, ...)
```

#### 1.15 Window Join
```
DataStream,DataStream → DataStream
```
在给定的键和公共窗口上对两个数据流进行 `join`。

Java版本:
```java
dataStream.join(otherStream)
    .where(<key selector>).equalTo(<key selector>)
    .window(TumblingEventTimeWindows.of(Time.seconds(3)))
    .apply (new JoinFunction () {...});
```
Scala版本:
```scala
dataStream.join(otherStream)
    .where(<key selector>).equalTo(<key selector>)
    .window(TumblingEventTimeWindows.of(Time.seconds(3)))
    .apply { ... }
```

#### 1.16 Window CoGroup
```
DataStream,DataStream → DataStream
```
在给定键和公共窗口上对两个数据流进行组合。

Java版本:
```java
dataStream.coGroup(otherStream)
    .where(0).equalTo(1)
    .window(TumblingEventTimeWindows.of(Time.seconds(3)))
    .apply (new CoGroupFunction () {...});
```
Scala版本:
```scala
dataStream.coGroup(otherStream)
    .where(0).equalTo(1)
    .window(TumblingEventTimeWindows.of(Time.seconds(3)))
    .apply {}
```

#### 1.17 Split
```
DataStream → SplitStream
```
根据一些标准将流分成两个或更多流。

Java版本:
```java
SplitStream<Integer> split = someDataStream.split(new OutputSelector<Integer>() {
    @Override
    public Iterable<String> select(Integer value) {
        List<String> output = new ArrayList<String>();
        if (value % 2 == 0) {
            output.add("even");
        }
        else {
            output.add("odd");
        }
        return output;
    }
});
```
Scala版本:
```scala
val split = someDataStream.split(
  (num: Int) =>
    (num % 2) match {
      case 0 => List("even")
      case 1 => List("odd")
    }
)
```

#### 1.18 Select
```
SplitStream → DataStream
```
从分流中选择一个或多个流。

Java版本：
```Java
SplitStream<Integer> split;
DataStream<Integer> even = split.select("even");
DataStream<Integer> odd = split.select("odd");
DataStream<Integer> all = split.select("even","odd");
```
Scala版本:
```scala
val even = split select "even"
val odd = split select "odd"
val all = split.select("even","odd")
```

#### 1.19 Extract Timestamps
```
DataStream → DataStream
```
从记录中提取时间戳，以便与使用事件时间语义的窗口一起工作。

Java版本:
```Java
stream.assignTimestamps (new TimeStampExtractor() {...});
```
Scala版本:
```scala
stream.assignTimestamps { timestampExtractor }
```

### 2. Physical partitioning

通过以下功能，Flink 还可以在转换后的确切流分区上进行低层次的控制（如果需要）。

#### 2.1 Custom partitioning
```
DataStream → DataStream
```
使用用户自定义的分区器为每个元素选择指定的任务。

```java
dataStream.partitionCustom(partitioner, "someKey");
dataStream.partitionCustom(partitioner, 0);
```

#### 2.2 Random partitioning
```
DataStream → DataStream
```
根据均匀分布随机分配元素。

```java
dataStream.shuffle();
```

#### 2.3 Rebalancing (Round-robin partitioning)
```
DataStream → DataStream
```
对元素循环分区，为每个分区创建相同的负载。在在数据倾斜时用于性能优化。

```java
dataStream.rebalance();
```

#### 2.4 Rescaling
```
DataStream → DataStream
```
为下游操作的子集循环分配元素。这非常有用，如果你想要在管道中使用，例如，从一个数据源的每个并行实例中输出到几个映射器的子集上来分配负载，但不希望发生 `rebalance()` 的完全重新平衡。这只需要本地数据传输，而不是通过网络传输数据，具体取决于其他配置值，例如 `TaskManager` 的插槽数。

上游操作向其发送元素的下游操作的子集取决于上游和下游操作的并行度。例如，如果上游操作并行度为2并且下游操作并行度为4，则一个上游操作将向两个下游操作分配元素，而另一个上游操作将分配给另外两个下游操作。另一方面，如果下游操作并行度为2而上游操作并行度为4，则两个上游操作将分配给一个下游操作，而另外两个上游操作将分配给另一个下游操作。

存在不同并行度不是成倍数关系，或者多个下游操作具有来自上游操作的不同数量的输入的情况。

这个图显示了在上面的例子中的连接模式：
![](https://github.com/sjf0115/PubLearnNotes/blob/master/image/Flink/flink-stream-operators-overall.png?raw=true)

```java
dataStream.rescale();
```

#### 2.5 Broadcasting
```
DataStream → DataStream
```
将元素广播到每个分区。
```
dataStream.broadcast()
```

### 3. 任务链 和 资源组

链接两个连续的转换操作意味着将它们共同定位在同一个线程中以获得更好的性能。如果可能的话，Flink默认链接算子（例如，两个连续的 `map` 转换）。如果需要，API可以对链接进行精细控制。

如果要禁用整个作业中的链接，请使用 `StreamExecutionEnvironment.disableOperatorChaining（）`。对于更细粒度的控制，可用使用以下函数。请注意，这些函数只能在 `DataStream` 转换操作之后使用，因为它们引用上一个转换。例如，你可以使用 `someStream.map（...）.startNewChain（）`，但不能使用 `someStream.startNewChain（）`。

资源组是 Flink 中的插槽，请参阅[插槽](https://ci.apache.org/projects/flink/flink-docs-release-1.4/ops/config.html#configuring-taskmanager-processing-slots)。如果需要，你可以在不同的插槽中手动隔离算子。

#### 3.1 开始一个新链

从这个算子开始，开始一个新的链。将这两个 `mapper` 链接，并且 `filter` 不会链接到第一个 `mapper`。
```java
someStream.filter(...).map(...).startNewChain().map(...);
```

#### 3.2 取消链

不会将`map`算子链接到链上：
```java
someStream.map(...).disableChaining();
```

#### 3.3 设置插槽共享组

设置操作的插槽共享组。Flink会将使用相同插槽共享组的操作放入同一插槽，同时保持在其他插槽中没有插槽共享组的操作。这可以用来隔离插槽。如果所有输入操作位于同一个插槽共享组中，则插槽共享组将继承自输入操作。缺省插槽共享组的名称为 `default`，可通过调用 `slotSharingGroup（“default”）`将操作显式放入此组。
```java
someStream.filter(...).slotSharingGroup("name");
```

> 备注：

> Flink 版本： 1.4

原文： https://ci.apache.org/projects/flink/flink-docs-release-1.4/dev/stream/operators/index.html
