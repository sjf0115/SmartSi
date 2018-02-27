---
layout: post
author: sjf0115
title: Scala 学习笔记之提取器
date: 2018-02-27 10:00:01
tags:
  - Scala

categories: Scala
permalink: scala-notes-apply-update
---

### 1. apply和update方法

Scala允许你使用如下函数调用语法:
```scala
f(arg1, arg2, ...)
```
扩展到可以应用于函数之外的值．如果 `f` 不是函数或方法，那么这个表达式就等同于调用:
```scala
f.apply(arg1, arg2, ...)
```
如果它出现在赋值语句的等号左侧:
```scala
f(arg1, arg2, ...) = value
```
则等同于调用:
```scala
f.update(arg1, arg2, ..., value)
```

应用场景:

(1) 常被用于数组和映射:
```scala
val scores = new scala.collection.mutable.HashMap[String, Int]
scores("Bob") = 100 // 调用scores.update("Bob", 100)
val bobScores = scores("Bob") // 调用scores.apply("Bob")
```
(2) 同样经常用在伴生对象中，用来构造对象而不用显示的使用new:
```scala
class Fraction (n: Int, d: Int){
  ...
}

object Fraction{
  def apply(n: Int, d: Int) = new Fraction(n, d)
}

// 使用
val result = Fraction(3, 4) * Fraction(2, 5)
```

### 2. 提取器

所谓提取器就是一个带有 `unapply` 方法的对象．可以把 `unapply` 方法理解为伴生对象中 `apply` 方法的反向操作. `apply` 方法接受构造参数，然后将他们变成对象．而 `unapply` 方法接受一个对象，然后从中提取值(通常这些值就是当初用来构造该对象的值)．

例如上面例子中的 `Fraction` 类， `apply` 方法从分子和分母创建出一个分数，而 `unapply` 方法则是去取出分子和分母:

(1) 可以在变量定义时使用:
```scala
// a b 分别被初始化成运算结果的分子和分母
var Fraction(a, b) = Fraction(3, 4) * Fraction(2, 5)
```
(2) 也可以用于模式匹配:
```scala
// a 和 b 分别绑到分子和分母
case Fraction(a, b) =>  ...
```
通常而言，模式匹配可能会失败，因此 `unapply` 方法返回的是一个Option．它包含一个元组，每个匹配到的变量各有一个值与之对应．下面中返回一个 `Option[(Int, Int)]`
```scala
class Fraction (n: Int, d: Int){
  ...
}

object Fraction{
  def apply(n: Int, d: Int) = new Fraction(n, d)
  def unapply(input: Fraction) = if( input.den == 0 ) None else Some( (input.num, input.den) )
}
```
> 备注
```
分母为0时返回None，表示无匹配
```

在上面例子中，`apply` 和 `unapply` 互为反向，但不一定总是互为反向．我们可以用提取器从任何类型的对象中提取信息．例如我们可以从字符串中提取名字和姓氏:
```scala
// 提取器
object Name{
    def unapply(input: String) = {
      val pos = input.indexOf(" ")
      if(pos == -1) Node
      else Some( (input.substring(0, pos), input.substring(pos + 1)) )
    }
}

val author = "Lionel Messi"
// 调用Name.unapply(author)
val Name(first, last) = author
// First Name is Lionel and last name is Messi
println("First Name is " + first + " and last name is " + last)
```
### 3. 带单个参数或无参数的提取器

在Scala中，并没有只带一个组件的元组．如果 `unapply` 方法要提取单值，则应该返回一个目标类型的 `Option`:
```scala
object Number {
  def unapply(input: String) : Option[Int] = {
    try{
      Some (Integer.parseInt(input.trim))
    }
    catch{
      case ex: NumberFormatException => None
    }
  }
}
```
可以使用这个提取器，从字符串中提取数字:
```scala
val Number(n) = "1990"
```
提取器也可以只是测试输入的数据而并不将其值提取出来，只需unapply方法返回Boolean:
```scala
object IsContainZero{
  def unapply(input: String) = input.contains("0")
}
```
### 4. unapplySeq方法

如果要提取任意长度的值的序列，我们需要使用 `unapplySeq` 来命名我们的方法．它返回一个 `Option[Seq[A]]`，其中A是被提取的值的类型:
```scala
object Names{
  def unapplySeq(input: String): Option[Seq[String]] = {
    if(input.trim == "") None else Some(input.trim.split("\\s+"))
  }
}

val namesStr = "Tom Lily Lucy"
val Names(first, second, third) = namesStr
// the first name is Tom and the second name is Lily and the third name is Lucy
println(s"the first name is $first and the second name is $second and the third name is $third")
```

来源于： 快学Scala
