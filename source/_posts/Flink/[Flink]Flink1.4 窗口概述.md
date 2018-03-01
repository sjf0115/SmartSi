---
layout: post
author: sjf0115
title: Flink1.4 窗口概述
date: 2018-02-28 17:17:17
tags:
  - Flink
  - Flink Stream

categories: Flink
permalink: flink-stream-windows-overall
---

Windows(窗口)是处理无限数据流的核心。窗口将流分解成有限大小的"桶"，在上面我们可以进行计算。本文将重点介绍 Flink 中的窗口，以及常见的窗口类型。

一个窗口化的 Flink 程序一般结构如下。第一个片段指的是指定 key 的数据流（`keyed streams`），而第二个未指定key的数据流。可以看出，唯一的区别是指定 key 的数据流调用了 `keyBy()` 以及 `window()` 方法变为未指定 key 数据流下的 `windowAll()` 方法。

Keyed Windows：
```
stream
       .keyBy(...)          <-  keyed versus non-keyed windows
       .window(...)         <-  required: "assigner"
      [.trigger(...)]       <-  optional: "trigger" (else default trigger)
      [.evictor(...)]       <-  optional: "evictor" (else no evictor)
      [.allowedLateness()]  <-  optional, else zero
       .reduce/fold/apply() <-  required: "function"
```

Non-Keyed Windows：
```
stream
       .windowAll(...)      <-  required: "assigner"
      [.trigger(...)]       <-  optional: "trigger" (else default trigger)
      [.evictor(...)]       <-  optional: "evictor" (else no evictor)
      [.allowedLateness()]  <-  optional, else zero
       .reduce/fold/apply() <-  required: "function"
```

在上面，方括号 `[...]` 中的命令是可选的。这表明 Flink 允许你可以以多种不同的方式自定义你的窗口逻辑，以便更好的满足你的需求。

### 1. 窗口生命周期

简而言之，一旦属于这个窗口的第一个元素到达，就会创建该窗口，当时间(事件时间或处理时间)到达其结束时间戳加上用户指定的可允许延迟的时间戳，窗口将被完全删除。Flink 保证仅对基于时间的窗口进行删除，并不适用于其他类型的窗口，例如，全局窗口（具体请参阅下面的窗口分配器）。举个例子，使用基于事件时间的窗口策略，每隔5分钟创建一个不重叠的窗口，并且允许可以有1分钟的延迟时间。当第一个带有时间戳的元素落入12:00至12:05时间间隔内时，Flink 创建一个新窗口，当时间戳到达 12:06 时，窗口将被删除。

另外，每个窗口都将有一个触发器和一个函数(例如 `WindowFunction`， `ReduceFunction` 或 `FoldFunction`)。这个函数包含应用于窗口内容的计算，而触发器指定了窗口使用该函数的条件。触发策略可能是"当窗口中的元素个数大于4"，或"当 `watermark` 通过窗口末尾"。触发器还可以决定在创建窗口和删除窗口之间的任何时间内清除窗口内容。在这种情况下，清除仅指窗口中的元素，而不是窗口的元数据。这意味着新数据仍然可以添加到该窗口。

除了上述之外，你还可以指定一个 `Evictor`，在触发器触发之后以及在应用该函数之前和/或之后从窗口中移除元素。

### 2. Keyed vs Non-Keyed Windows

首先要指定的第一件事就是你的数据流是否应该指定 `key`。这必须在定义窗口之前完成。使用 `keyBy()` 可以将无限数据流分解成指定 key 的逻辑上的数据流。如果未调用 `keyBy()`，则你的数据流未指定 key。

在指定 key 的数据流的情况下，你传入进来的事件的任何属性都可以用作 key([更多细节](http://smartsi.club/2018/01/04/flink-how-to-specifying-keys/))。指定 key 的数据流可以允许通过多个任务并行执行窗口计算，因为每个逻辑数据流可以独立于其余的进行处理。指向相同 key 的所有元素将被发送到相同的并行任务上。

在未指定 key 的数据流的情况下，你的原始数据流不会被分割成多个逻辑数据流，并且所有窗口逻辑将由单个任务执行，即以1个的并行度执行。

### 3. 窗口分配器

在确定数据流是否指定 key 之后，下一步就是定义窗口分配器。窗口分配器定义了元素如何分配给窗口。这通过在 `window()`(指定key数据流)或 `windowAll()`(未指定key数据流)调用中指定你选择的窗口分配器来完成。

窗口分配器负责将每个传入的元素分配给一个或多个窗口。Flink 内置了一些用于解决常见用例的窗口分配器，有滚动窗口，滑动窗口，会话窗口和全局窗口。你还可以通过继承 `WindowAssigner` 类实现自定义窗口分配器。所有内置窗口分配器(全局窗口除外)根据时间将元素分配给窗口，可以是处理时间或事件时间。请参阅[事件时间](http://smartsi.club/2018/01/04/flink-stream-event-time-and-processing-time/)，了解处理时间和事件时间之间的差异以及如何生成时间戳和`watermarks`。

在下文中，我们将展示 Flink 的内置窗口分配器的工作原理以及它们在 `DataStream` 程序中的使用方式。以下图形可视化每个分配器的运行。紫色圆圈表示数据流中的元素，它们被某些key（在我们这个例子下为用 `user1`，`user2` 和 `user3`）分区。x轴显示时间进度。

#### 3.1 滚动窗口

滚动窗口分配器将每个元素分配给固定大小的窗口。滚动窗口大小固定且不重叠。例如，如果指定大小为5分钟的滚动窗口，则将执行当前窗口，并且每五分钟将启动一个新窗口，如下图所示:

![](https://github.com/sjf0115/PubLearnNotes/blob/master/image/Flink/flink-stream-windows-overall-1.png?raw=true)

以下代码显示如何使用滚动窗口：

Java版本:
```java
DataStream<T> input = ...;

// 基于事件事件的滚动窗口
input
    .keyBy(<key selector>)
    .window(TumblingEventTimeWindows.of(Time.seconds(5)))
    .<windowed transformation>(<window function>);

// 基于处理时间的滚动窗口
input
    .keyBy(<key selector>)
    .window(TumblingProcessingTimeWindows.of(Time.seconds(5)))
    .<windowed transformation>(<window function>);

// daily tumbling event-time windows offset by -8 hours.
input
    .keyBy(<key selector>)
    .window(TumblingEventTimeWindows.of(Time.days(1), Time.hours(-8)))
    .<windowed transformation>(<window function>);
```

Scala版本:
```scala
val input: DataStream[T] = ...

// tumbling event-time windows
input
    .keyBy(<key selector>)
    .window(TumblingEventTimeWindows.of(Time.seconds(5)))
    .<windowed transformation>(<window function>)

// tumbling processing-time windows
input
    .keyBy(<key selector>)
    .window(TumblingProcessingTimeWindows.of(Time.seconds(5)))
    .<windowed transformation>(<window function>)

// daily tumbling event-time windows offset by -8 hours.
input
    .keyBy(<key selector>)
    .window(TumblingEventTimeWindows.of(Time.days(1), Time.hours(-8)))
    .<windowed transformation>(<window function>)
```

可以通过使用 `Time.milliseconds(x)`， `Time.seconds(x)`， `Time.minutes(x)` 来指定时间间隔。

如上一个例子中所示，滚动窗口分配器还可以使用一个可选的偏移量参数，可以用来改变窗口的对齐方式。例如，没有偏移量的情况下，按小时滚动窗口与 `epoch` （指的是一个特定的时间：`1970-01-01 00:00:00 UTC`）对齐，那么你将获得如`1：00：00.000 - 1：59：59.999`，`2：00：00.000 - 2：59：59.999`等窗口。如果你想改变，你可以给一个偏移量。以15分钟的偏移量为例，那么你将获得`1：15：00.000 - 2：14：59.999`，`2：15：00.000 - 3：14：59.999`等。偏移量的一个重要用例是将窗口调整为时区而不是UTC-0。例如，在中国，你必须指定 `Time.hours(-8)` 的偏移量。

#### 3.2 滑动窗口

滑动窗口分配器将每个元素分配给固定窗口大小的窗口。类似于滚动窗口分配器，窗口的大小由窗口大小(`window size`)参数配置。另外一个窗口滑动参数控制滑动窗口的启动频率(译者注：滑动大小)。因此，如果滑动大小小于窗口大小，滑动窗口可以重叠。在这种情况下，元素可以被分配到多个窗口。

例如，你可以使用窗口大小为10分钟的窗口，滑动大小为5分钟。这样，每5分钟会生成一个窗口，包含最后10分钟内到达的事件，如下图所示。

![](https://github.com/sjf0115/PubLearnNotes/blob/master/image/Flink/flink-stream-windows-overall-2.png?raw=true)

以下代码显示如何使用滑动窗口:

Java版本:
```java
DataStream<T> input = ...;

// sliding event-time windows
input
    .keyBy(<key selector>)
    .window(SlidingEventTimeWindows.of(Time.seconds(10), Time.seconds(5)))
    .<windowed transformation>(<window function>);

// sliding processing-time windows
input
    .keyBy(<key selector>)
    .window(SlidingProcessingTimeWindows.of(Time.seconds(10), Time.seconds(5)))
    .<windowed transformation>(<window function>);

// sliding processing-time windows offset by -8 hours
input
    .keyBy(<key selector>)
    .window(SlidingProcessingTimeWindows.of(Time.hours(12), Time.hours(1), Time.hours(-8)))
    .<windowed transformation>(<window function>);
```

Scala版本:
```scala
val input: DataStream[T] = ...

// sliding event-time windows
input
    .keyBy(<key selector>)
    .window(SlidingEventTimeWindows.of(Time.seconds(10), Time.seconds(5)))
    .<windowed transformation>(<window function>)

// sliding processing-time windows
input
    .keyBy(<key selector>)
    .window(SlidingProcessingTimeWindows.of(Time.seconds(10), Time.seconds(5)))
    .<windowed transformation>(<window function>)

// sliding processing-time windows offset by -8 hours
input
    .keyBy(<key selector>)
    .window(SlidingProcessingTimeWindows.of(Time.hours(12), Time.hours(1), Time.hours(-8)))
    .<windowed transformation>(<window function>)
```

可以通过使用 `Time.milliseconds(x)`，`Time.seconds(x)`，`Time.minutes(x)` 来指定时间间隔。

如上一个例子所示，滑动窗口分配器也可以使用一个可选的偏移量参数，用来改变窗口的对齐方式。例如，没有偏移量的情况下，按小时滑动窗口大小为30分钟的例子下，你将获得如`1：00：00.000 - 1：59：59.999`，`1：30：00.000 - 2：29：59.999`等窗口。如果你想改变，你可以给一个偏移量。以15分钟的偏移量为例，那么你将获得`1：15：00.000 - 2：14：59.999`，`1：45：00.000 - 2：44：59.999`等。偏移量的一个重要用例是将窗口调整为时区而不是UTC-0。例如，在中国，你必须指定`Time.hours(-8)`的偏移量。

#### 3.3 会话窗口

会话窗口分配器通过活动会话对元素进行分组。与滚动窗口和滑动窗口相比，会话窗口不会重叠，也没有固定的开始和结束时间。相反，当会话窗口在一段时间内没有接收到元素时会关闭，即当发生不活动的间隙时。会话窗口分配器配置一个会话间隙，定义了所需的不活动时长。当此时间段到期时，当前会话关闭，后续元素被分配到新的会话窗口。

![](https://github.com/sjf0115/PubLearnNotes/blob/master/image/Flink/flink-stream-windows-overall-3.png?raw=true)

以下代码显示如何使用会话窗口:

Java版本:
```java
DataStream<T> input = ...;

// event-time session windows
input
    .keyBy(<key selector>)
    .window(EventTimeSessionWindows.withGap(Time.minutes(10)))
    .<windowed transformation>(<window function>);

// processing-time session windows
input
    .keyBy(<key selector>)
    .window(ProcessingTimeSessionWindows.withGap(Time.minutes(10)))
    .<windowed transformation>(<window function>);
```

Scala版本:
```scala
val input: DataStream[T] = ...

// event-time session windows
input
    .keyBy(<key selector>)
    .window(EventTimeSessionWindows.withGap(Time.minutes(10)))
    .<windowed transformation>(<window function>)

// processing-time session windows
input
    .keyBy(<key selector>)
    .window(ProcessingTimeSessionWindows.withGap(Time.minutes(10)))
    .<windowed transformation>(<window function>)
```
可以通过使用 `Time.milliseconds(x)`， `Time.seconds(x)`， `Time.minutes(x)` 来指定时间间隔。

由于会话窗口没有固定的开始时间和结束时间，因此它们的执行与滚动窗口和滑动窗口不同。在内部，会话窗口算子为每个到达记录创建一个新窗口，如果它们之间的距离比定义的间隙更近，则将窗口合并在一起。为了可合并，会话窗口算子需要一个合并触发器和合并窗口函数，例如 `ReduceFunction` 或 `WindowFunction`（`FoldFunction`无法合并）。

#### 3.4 全局窗口

全局窗口分配器将具有相同 key 的所有元素分配给同一个全局窗口。这个窗口规范是仅在你同时指定自定义触发器时有用。否则，不会执行计算，因为全局窗口没有我们可以处理聚合元素的自然结束的点（译者注：即本身自己不知道窗口的大小，计算多长时间的元素）。

![](https://github.com/sjf0115/PubLearnNotes/blob/master/image/Flink/flink-stream-windows-overall-4.png?raw=true)

以下代码显示如何使用会话窗口:

Java版本:
```java
DataStream<T> input = ...;

input
    .keyBy(<key selector>)
    .window(GlobalWindows.create())
    .<windowed transformation>(<window function>);
```

Scala版本:
```scala
val input: DataStream[T] = ...

input
    .keyBy(<key selector>)
    .window(GlobalWindows.create())
    .<windowed transformation>(<window function>)
```


> 备注:

> Flink版本:1.4

原文:https://ci.apache.org/projects/flink/flink-docs-release-1.4/dev/stream/operators/windows.html
