---
layout: post
author: sjf0115
title: Hadoop Reducer 能否复用为 Combiner
date: 2017-12-06 09:39:01
tags:
  - Hadoop

categories: Hadoop
permalink: hadoop-can-reducer-always-be-reused-for-combiner
---

Combiner 函数是一个可选的中间函数，发生在 Map 阶段，Mapper 执行完成后立即执行。使用 Combiner 有如下两个优势：
- Combiner 可以用来减少发送到 Reducer 的数据量，从而提高网络效率。
- Combiner 可以用于减少发送到 Reducer 的数据量，这将提高 Reduce 端的效率，因为每个 reduce 函数将处理相比于未使用 Combiner 之前更少的记录。

Combiner 与 Reducer 结构相同，因为 Combiner 和 Reducer 都是对 Mapper 的输出进行处理。这给了我们一个复用 Reducer 作为 Combiner 的好机会。但问题是，复用 Reducer 作为 Combiner 总是可行的吗？

### 1. Reducer 作为 Combiner 的适用场景

假设我们在编写一个 MapReduce 程序来计算股票数据集中每只股票的最大收盘价。Mapper 将数据集中每条股票记录的股票代码作为 key 以及收盘价作为 value。Reducer 然后将循环遍历股票代码对应的所有收盘价，并从收盘价列表中计算最高收盘价。假设 Mapper 1 处理股票代码为 ABC 的 3 条记录，收盘价分别为 50、60 以及 111。我们假设 Mapper 2 处理股票代码为 ABC 的 2 条记录，收盘价分别为 100 和 31。那么 Reducer 将收到股票代码 ABC 五个收盘价：50、60、111、100 以及 31。Reducer 的工作非常简单，简单循环遍历所有收盘价，计算最高收盘价为 111。

我们可以在每个 Mapper 之后使用 Reducer 作为 Combiner。Mapper 1 上的 Combiner 会处理 3 个收盘价格：50、60 以及 111，并且仅输出 111，因为它是 3 个收盘价的最大值。Mapper 2 上的 Combiner 会处理 2 个收盘价格：100 和 31，并且仅输出 100，因为它是 2 个收盘价的最大值。现在使用 Combiner 之后，Reducer 仅处理股票代码 ABC 的 2 个收盘价(原先需要处理 5 个收盘价)，即来自 Mapper 1 的 111 和来自 Mapper 2 的 100，并且将从这两个值中计算出最大收盘价格为 111。

正如我们看到的，使用 Combiner 情况下 Reducer 输出与没有使用 Combiner 的输出结果是相同的，因此在这种情况下复用 Reducer 作为 Combiner 是没有问题。

### 2. Reducer 作为 Combiner 的不适用场景

假设我们在编写一个 MapReduce 程序来计算股票数据集中每只股票的平均交易量。Mapper 将数据集中每条股票记录的股票代码作为 key 以及交易量作为 value。Reducer 然后将循环遍历股票代码对应的所有交易量，并从交易量列表中计算出平均交易量。假设 Mapper 1 处理股票代码为 ABC 的 3 条记录，收盘价分别为 50、60 以及 111。我们假设 Mapper 2 处理股票代码为 ABC 的 2 条记录，收盘价分别为 100 和 31。那么 Reducer 将收到股票代码 ABC 五个收盘价：50、60、111、100 以及 31。Reducer 的工作非常简单，简单循环遍历所有交易量，并将计算出平均交易量为 70.4：
```
(50 + 60 + 111 + 100 + 31) /  5 = 70.4
```
让我们看看如果我们在每个 Mapper 之后复用 Reducer 作为 Combiner 会发生什么。Mapper 1 上的 Combiner 会处理 3 个交易量：50、60 以及 111，并计算出三个交易量的平均交易量为 73.66。Mapper 2 上的 Combiner 会处理 2 个交易量：100 和 31，并计算出两个交易量的平均交易量为 65.5。那么在复用 Reducer 作为 Combiner 的情况下，Reducer 仅处理股票代码 ABC 的 2 个平均交易量，来自 Mapper 1 的 73.66 和来自 Mapper 2 的 65.5，并计算股票代码 ABC 最终的平均交易量为 69.58：
```
(73.66 + 65.5) / 2 = 69.58
```
这与我们不复用 Reducer 作为 Combiner 得出的结果不一样，因此复用 Reducer 作为 Combiner 得出平均交易量是不正确的。所以我们可以看到 Reducer 不能总是被用于 Combiner。所以，当你决定复用 Reducer 作为 Combiner 的时候，你需要问自己这样一个问题：使用 Combiner 与不使用 Combiner 的输出结果是否一样？

### 3. 区别

Combiner 需要实现 Reducer 接口。Combiner 只能用于特定情况：
- 与 Reducer 不同，Combiner 有一个约束，Combiner 输入/输出键和值类型必须与 Mapper 的输出键和值类型相匹配。而 Reducer 只是输入键和值类型与 Mapper 的输出键和值类型相匹配。
- Combiner 只能用于满足交换律（a.b = b.a）和结合律（a.(b.c)= (a.b).c）的情况。这也意味着 Combiner 可能只能用于键和值的一个子集或者可能不能使用。
- Reducer 可以从多个 Mapper 获取数据。Combiner 只能从一个 Mapper 获取其输入。

欢迎关注我的公众号和博客：

![](https://github.com/sjf0115/ImageBucket/blob/main/Other/smartsi.jpg?raw=true)

原文：http://hadoopinrealworld.com/can-reducer-always-be-reused-for-combiner/
