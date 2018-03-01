---
layout: post
author: sjf0115
title: Flink1.4 窗口函数
date: 2018-03-01 09:41:17
tags:
  - Flink
  - Flink Stream

categories: Flink
permalink: flink-stream-windows-function
---

在定义[窗口分配器](http://smartsi.club/2018/02/28/flink-stream-windows-overall/)之后，我们需要在每个窗口上指定我们要执行的计算。这是窗口函数的责任，一旦系统确定窗口准备好处理数据，窗口函数就处理每个窗口中的元素。

窗口函数可以是 `ReduceFunction`， `AggregateFunction`, `FoldFunction` 或 `ProcessWindowFunction`。前两个函数执行效率更高，因为 Flink 可以在每个窗口中元素到达时增量地聚合。`ProcessWindowFunction` 将获得一个窗口内所有元素的迭代器以及元素所在窗口的附加元信息。

使用 `ProcessWindowFunction` 的窗口转换操作不能像其他那样有效率，是因为 Flink 在调用该函数之前必须在内部缓存窗口中的所有元素。这可以通过将 `ProcessWindowFunction` 与 `ReduceFunction`， `AggregateFunction` 或 `FoldFunction` 组合使用来获得窗口元素的增量聚合以及`WindowFunction`接收的附加窗口元数据。

### 1. ReduceFunction

`ReduceFunction` 指定如何组合输入数据的两个元素以产生相同类型的输出元素。Flink 使用 `ReduceFunction` 增量聚合窗口的元素。

`ReduceFunction`可以如下定义和使用:

Java版本:
```java
DataStream<Tuple2<String, Long>> input = ...;

input
    .keyBy(<key selector>)
    .window(<window assigner>)
    .reduce(new ReduceFunction<Tuple2<String, Long>> {
      public Tuple2<String, Long> reduce(Tuple2<String, Long> v1, Tuple2<String, Long> v2) {
        return new Tuple2<>(v1.f0, v1.f1 + v2.f1);
    }
});
```

Scala版本:
```scala
val input: DataStream[(String, Long)] = ...

input
    .keyBy(<key selector>)
    .window(<window assigner>)
    .reduce { (v1, v2) => (v1._1, v1._2 + v2._2) }
```
上述示例获得窗口中的所有元素元组的第二个字段之和。

### 2. FoldFunction

`FoldFunction` 指定窗口的输入元素如何与输出类型的元素合并。`FoldFunction` 会被每一个加入到窗口中的元素和当前的输出值增量地调用，第一个元素与一个预定义的输出类型的初始值合并。

`FoldFunction` 可以如下定义和使用:

Java版本:
```java
DataStream<Tuple2<String, Long>> input = ...;

input
    .keyBy(<key selector>)
    .window(<window assigner>)
    .fold("", new FoldFunction<Tuple2<String, Long>, String>> {
       public String fold(String acc, Tuple2<String, Long> value) {
         return acc + value.f1;
       }
});
```
Scala版本:
```scala
val input: DataStream[(String, Long)] = ...

input
    .keyBy(<key selector>)
    .window(<window assigner>)
    .fold("") { (acc, v) => acc + v._2 }
```

上述示例将所有输入元素的Long值追加到初始化为空的字符串中。

> 备注

> fold()不能应用于会话窗口或者其他可合并的窗口中。

### 3. AggregateFunction

`AggregateFunction` 是 `ReduceFunction` 的通用版本，具有三种类型：输入类型（`IN`），累加器类型（`ACC`）和输出类型（`OUT`）。输入类型是输入流中元素的类型，`AggregateFunction` 有一个用于将一个输入元素添加到累加器的方法。该接口还具有创建初始累加器的方法，用于将两个累加器合并到一个累加器中，并从累加器中提取输出（类型为`OUT`）。我们将在下面的例子中看到它是如何工作的。

与 `ReduceFunction` 相同，Flink 将在窗口到达时递增地聚合窗口的输入元素。

Java版本:
```java
/**
 * The accumulator is used to keep a running sum and a count. The {@code getResult} method
 * computes the average.
 */
private static class AverageAggregate
    implements AggregateFunction<Tuple2<String, Long>, Tuple2<Long, Long>, Double> {
  @Override
  public Tuple2<Long, Long> createAccumulator() {
    return new Tuple2<>(0L, 0L);
  }

  @Override
  public Tuple2<Long, Long> add(Tuple2<String, Long> value, Tuple2<Long, Long> accumulator) {
    return new Tuple2<>(accumulator.f0 + value.f1, accumulator.f1 + 1L);
  }

  @Override
  public Double getResult(Tuple2<Long, Long> accumulator) {
    return accumulator.f0 / accumulator.f1;
  }

  @Override
  public Tuple2<Long, Long> merge(Tuple2<Long, Long> a, Tuple2<Long, Long> b) {
    return new Tuple2<>(a.f0 + b.f0, a.f1 + b.f1);
  }
}

DataStream<Tuple2<String, Long>> input = ...;

input
    .keyBy(<key selector>)
    .window(<window assigner>)
    .aggregate(new AverageAggregate());
```
Scala版本:
```scala
/**
 * The accumulator is used to keep a running sum and a count. The [getResult] method
 * computes the average.
 */
class AverageAggregate extends AggregateFunction[(String, Long), (Long, Long), Double] {
  override def createAccumulator() = (0L, 0L)

  override def add(value: (String, Long), accumulator: (Long, Long)) =
    (accumulator._1 + value._2, accumulator._2 + 1L)

  override def getResult(accumulator: (Long, Long)) = accumulator._1 / accumulator._2

  override def merge(a: (Long, Long), b: (Long, Long)) =
    (a._1 + b._1, a._2 + b._2)
}

val input: DataStream[(String, Long)] = ...

input
    .keyBy(<key selector>)
    .window(<window assigner>)
    .aggregate(new AverageAggregate)
```
上面的例子计算窗口中元素的第二个字段的平均值。

### 4. ProcessWindowFunction

`ProcessWindowFunction` 获得一个窗口内所有元素的 `Iterable`，以及一个可以访问时间和状态信息的 `Context` 对象，这使得它可以提供比其他窗口函数更大的灵活性。这是以牺牲性能和资源消耗为代价的，因为元素不能增量地聚合，而是需要在内部进行缓冲，直到窗口被认为准备好进行处理为止。

`ProcessWindowFunction` 的结构如下所示：

Java版本:
```java
public abstract class ProcessWindowFunction<IN, OUT, KEY, W extends Window> implements Function {

    /**
     * Evaluates the window and outputs none or several elements.
     *
     * @param key The key for which this window is evaluated.
     * @param context The context in which the window is being evaluated.
     * @param elements The elements in the window being evaluated.
     * @param out A collector for emitting elements.
     *
     * @throws Exception The function may throw exceptions to fail the program and trigger recovery.
     */
    public abstract void process(
            KEY key,
            Context context,
            Iterable<IN> elements,
            Collector<OUT> out) throws Exception;

   	/**
   	 * The context holding window metadata.
   	 */
   	public abstract class Context implements java.io.Serializable {
   	    /**
   	     * Returns the window that is being evaluated.
   	     */
   	    public abstract W window();

   	    /** Returns the current processing time. */
   	    public abstract long currentProcessingTime();

   	    /** Returns the current event-time watermark. */
   	    public abstract long currentWatermark();

   	    /**
   	     * State accessor for per-key and per-window state.
   	     *
   	     * <p><b>NOTE:</b>If you use per-window state you have to ensure that you clean it up
   	     * by implementing {@link ProcessWindowFunction#clear(Context)}.
   	     */
   	    public abstract KeyedStateStore windowState();

   	    /**
   	     * State accessor for per-key global state.
   	     */
   	    public abstract KeyedStateStore globalState();
   	}

}
```
Scala版本:
```scala
abstract class ProcessWindowFunction[IN, OUT, KEY, W <: Window] extends Function {

  /**
    * Evaluates the window and outputs none or several elements.
    *
    * @param key      The key for which this window is evaluated.
    * @param context  The context in which the window is being evaluated.
    * @param elements The elements in the window being evaluated.
    * @param out      A collector for emitting elements.
    * @throws Exception The function may throw exceptions to fail the program and trigger recovery.
    */
  def process(
      key: KEY,
      context: Context,
      elements: Iterable[IN],
      out: Collector[OUT])

  /**
    * The context holding window metadata
    */
  abstract class Context {
    /**
      * Returns the window that is being evaluated.
      */
    def window: W

    /**
      * Returns the current processing time.
      */
    def currentProcessingTime: Long

    /**
      * Returns the current event-time watermark.
      */
    def currentWatermark: Long

    /**
      * State accessor for per-key and per-window state.
      */
    def windowState: KeyedStateStore

    /**
      * State accessor for per-key global state.
      */
    def globalState: KeyedStateStore
  }

}
```
关键参数是通过 `KeySelector` 提取为 `keyBy（）` 调用指定的键。在元组索引键或字符串字段引用的情况下，此键类型始终为元组，并且必须手动将其转换为正确大小的元组以提取关键字段。一个 `ProcessWindowFunction` 可以像这样定义和使用：

Java版本:
```java
DataStream<Tuple2<String, Long>> input = ...;

input
    .keyBy(<key selector>)
    .window(<window assigner>)
    .process(new MyProcessWindowFunction());

/* ... */

public class MyProcessWindowFunction implements ProcessWindowFunction<Tuple<String, Long>, String, String, TimeWindow> {

  void process(String key, Context context, Iterable<Tuple<String, Long>> input, Collector<String> out) {
    long count = 0;
    for (Tuple<String, Long> in: input) {
      count++;
    }
    out.collect("Window: " + context.window() + "count: " + count);
  }
}
```
Scala版本:
```scala
val input: DataStream[(String, Long)] = ...

input
    .keyBy(<key selector>)
    .window(<window assigner>)
    .process(new MyProcessWindowFunction())

/* ... */

class MyProcessWindowFunction extends ProcessWindowFunction[(String, Long), String, String, TimeWindow] {

  def apply(key: String, context: Context, input: Iterable[(String, Long)], out: Collector[String]): () = {
    var count = 0L
    for (in <- input) {
      count = count + 1
    }
    out.collect(s"Window ${context.window} count: $count")
  }
}
```
上述示例显示了一个 `ProcessWindowFunction`，用于统计窗口中的元素。另外，窗口函数将有关窗口的信息添加到输出中。

> 备注

> 使用ProcessWindowFunction进行简单聚合（如count）的效率非常低。 下一节将展示ReduceFunction或AggregateFunction如何与ProcessWindowFunction组合以获得增量聚合以及ProcessWindowFunction的附加信息。

### 5. 使用增量聚合的ProcessWindowFunction

`ProcessWindowFunction` 可以与 `ReduceFunction` ， `AggregateFunction` 或 `FoldFunction` 组合使用，以便在元素到达窗口时增量聚合元素。当窗口关闭时，`ProcessWindowFunction`提供聚合结果。这允许增量计算窗口，同时也可以访问 `ProcessWindowFunction` 额外的窗口元信息。

> 备注

> 你也可以使用传统WindowFunction而不是ProcessWindowFunction进行增量窗口聚合。

#### 5.1 使用ReduceFunction的增量窗口聚合

以下示例展现了如何将增量式 `ReduceFunction` 与 `ProcessWindowFunction` 结合以返回窗口中的最小事件以及窗口的开始时间。

Java版本:
```java
DataStream<SensorReading> input = ...;

input
  .keyBy(<key selector>)
  .timeWindow(<window assigner>)
  .reduce(new MyReduceFunction(), new MyWindowFunction());

// Function definitions

private static class MyReduceFunction implements ReduceFunction<SensorReading> {

  public SensorReading reduce(SensorReading r1, SensorReading r2) {
      return r1.value() > r2.value() ? r2 : r1;
  }
}

private static class MyWindowFunction
    implements WindowFunction<SensorReading, Tuple2<Long, SensorReading>, String, TimeWindow> {

  public void apply(String key,
                    TimeWindow window,
                    Iterable<SensorReading> minReadings,
                    Collector<Tuple2<Long, SensorReading>> out) {
      SensorReading min = minReadings.iterator().next();
      out.collect(new Tuple2<Long, SensorReading>(window.getStart(), min));
  }
}
```

Scala版本:
```scala  
val input: DataStream[SensorReading] = ...

input
  .keyBy(<key selector>)
  .timeWindow(<window assigner>)
  .reduce(
    (r1: SensorReading, r2: SensorReading) => { if (r1.value > r2.value) r2 else r1 },
    ( key: String,
      window: TimeWindow,
      minReadings: Iterable[SensorReading],
      out: Collector[(Long, SensorReading)] ) =>
      {
        val min = minReadings.iterator.next()
        out.collect((window.getStart, min))
      }
  )
```
#### 5.2 使用AggregateFunction的增量窗口聚合

以下示例显示了如何将增量式 `AggregateFunction` 与 `ProcessWindowFunction` 结合来计算平均值，并将键与平均值一起输出。

Java版本:
```
DataStream<Tuple2<String, Long> input = ...;

input
  .keyBy(<key selector>)
  .timeWindow(<window assigner>)
  .aggregate(new AverageAggregate(), new MyProcessWindowFunction());

// Function definitions

/**
 * The accumulator is used to keep a running sum and a count. The {@code getResult} method
 * computes the average.
 */
private static class AverageAggregate
    implements AggregateFunction<Tuple2<String, Long>, Tuple2<Long, Long>, Double> {
  @Override
  public Tuple2<Long, Long> createAccumulator() {
    return new Tuple2<>(0L, 0L);
  }

  @Override
  public Tuple2<Long, Long> add(Tuple2<String, Long> value, Tuple2<Long, Long> accumulator) {
    return new Tuple2<>(accumulator.f0 + value.f1, accumulator.f1 + 1L);
  }

  @Override
  public Double getResult(Tuple2<Long, Long> accumulator) {
    return accumulator.f0 / accumulator.f1;
  }

  @Override
  public Tuple2<Long, Long> merge(Tuple2<Long, Long> a, Tuple2<Long, Long> b) {
    return new Tuple2<>(a.f0 + b.f0, a.f1 + b.f1);
  }
}

private static class MyProcessWindowFunction
    implements ProcessWindowFunction<Double, Tuple2<String, Double>, String, TimeWindow> {

  public void apply(String key,
                    Context context,
                    Iterable<Double> averages,
                    Collector<Tuple2<String, Double>> out) {
      Double average = averages.iterator().next();
      out.collect(new Tuple2<>(key, average));
  }
}
```
Scala版本:
```scala
val input: DataStream[(String, Long)] = ...

input
  .keyBy(<key selector>)
  .timeWindow(<window assigner>)
  .aggregate(new AverageAggregate(), new MyProcessWindowFunction())

// Function definitions

/**
 * The accumulator is used to keep a running sum and a count. The [getResult] method
 * computes the average.
 */
class AverageAggregate extends AggregateFunction[(String, Long), (Long, Long), Double] {
  override def createAccumulator() = (0L, 0L)

  override def add(value: (String, Long), accumulator: (Long, Long)) =
    (accumulator._1 + value._2, accumulator._2 + 1L)

  override def getResult(accumulator: (Long, Long)) = accumulator._1 / accumulator._2

  override def merge(a: (Long, Long), b: (Long, Long)) =
    (a._1 + b._1, a._2 + b._2)
}

class MyProcessWindowFunction extends ProcessWindowFunction[Double, (String, Double), String, TimeWindow] {

  def apply(key: String, context: Context, averages: Iterable[Double], out: Collector[(String, Double]): () = {
    var count = 0L
    for (in <- input) {
      count = count + 1
    }
    val average = averages.iterator.next()
    out.collect((key, average))
  }
}
```

#### 5.3 使用FoldFunction的增量窗口聚合

以下示例展现了增量式 `FoldFunction` 如何与 `WindowFunction` 结合以提取窗口中的事件数，并返回窗口的键和结束时间。

Java版本:
```java
DataStream<SensorReading> input = ...;

input
  .keyBy(<key selector>)
  .timeWindow(<window assigner>)
  .fold(new Tuple3<String, Long, Integer>("",0L, 0), new MyFoldFunction(), new MyWindowFunction())

// Function definitions

private static class MyFoldFunction
    implements FoldFunction<SensorReading, Tuple3<String, Long, Integer> > {

  public Tuple3<String, Long, Integer> fold(Tuple3<String, Long, Integer> acc, SensorReading s) {
      Integer cur = acc.getField(2);
      acc.setField(2, cur + 1);
      return acc;
  }
}

private static class MyWindowFunction
    implements WindowFunction<Tuple3<String, Long, Integer>, Tuple3<String, Long, Integer>, String, TimeWindow> {

  public void apply(String key,
                    TimeWindow window,
                    Iterable<Tuple3<String, Long, Integer>> counts,
                    Collector<Tuple3<String, Long, Integer>> out) {
    Integer count = counts.iterator().next().getField(2);
    out.collect(new Tuple3<String, Long, Integer>(key, window.getEnd(),count));
  }
}
```

Scala版本:
```scala
val input: DataStream[SensorReading] = ...

input
 .keyBy(<key selector>)
 .timeWindow(<window assigner>)
 .fold (
    ("", 0L, 0),
    (acc: (String, Long, Int), r: SensorReading) => { ("", 0L, acc._3 + 1) },
    ( key: String,
      window: TimeWindow,
      counts: Iterable[(String, Long, Int)],
      out: Collector[(String, Long, Int)] ) =>
      {
        val count = counts.iterator.next()
        out.collect((key, window.getEnd, count._3))
      }
  )
```

> 备注

> Flink版本:1.4


原文:https://ci.apache.org/projects/flink/flink-docs-release-1.4/dev/stream/operators/windows.html#window-functions
