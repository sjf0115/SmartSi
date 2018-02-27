---
layout: post
author: sjf0115
title: Scala 学习笔记之高阶函数
date: 2018-02-27 09:55:01
tags:
  - Scala

categories: Scala
permalink: scala-notes-higher-order-functions
---

Scala混合了面向对象和函数式的特性．在函数式编程语言中，函数可以像任何其他数据类型一样被传递和操作．如果想要给算法传入明细动作时，只需要将明细动作包在函数当中作为参数传入即可．

### 1. 作为值的函数
在Scala中，函数就和数字一样，可以在变量中存放:
```scala
import scala.math._

val num = 3.14 // num: Double = 3.14
val fun = ceil _  // fun: Double => Double = <function1>
println(num) // 3.14
println(fun(num)) // 4.0
```
上述代码将num设置为3.14，将fun设置为 `ceil` 函数．num的类型为 `Double`，fun的类型为 `(Double) => Double` (即接受并返回Double的函数)

> 备注

```
ceil函数后的 _ 表示确实指的是ceil这个函数，而不是碰巧忘记了给它传递参数
```

可以对函数做如下两件事:
- 调用它
- 传递它 存放在变量中，或者作为参数传递给另一个函数

Example:
```scala
// 调用
fun(num) // 4.0
// 传递
Array(3.14, 2.14, 1.14).map(fun) // Array(4.0, 3.0, 2.0)
```
> 备注
```
map方法接受一个函数参数，将它应用到数组中的所有值，然后返回结果的数组
```
### 2. 匿名函数

在Scala中，不需要给每一个函数命名，就像不用给每个数字命名一样:
```scala
(x: Double) => 3 * x
```
上述代码表示该函数将传递给它的参数乘以3．

对与上述匿名函数我们可以如下操作:

(1) 可以将函数存放在变量中:
```scala
val triple = (x: Double) => 3 * x
triple(2) // 6.0
```
上述代码等价于:
```scala
def triple(x:Double) = 3 * x
```
(2) 可以不用命名直接将函数传递给另一个函数:
```scala
Array(3.14, 2.14, 1.14).map((x: Double) => 3 * x)
```
### 3. 带函数参数的函数

下面是一个接受一个函数作为参数的函数:
```scala
def valueAtOneQuarter(fun: (Double) => Double) = fun(0.25)
valueAtOneQuarter(sqrt _) // 0.5 即 sqrt(0.25)
```
上述函数的参数类型为 `(Double) => Double`，即接受任何 `Double` 并返回 `Double` 的函数．

### 4. 参数类型推断

当你将一个匿名函数传递给一个函数时，Scala会尽可能帮助你推断出类型信息．不需要将代码写成如下:
```scala
valueAtOneQuarter( (x:Double) => 3 * x ) // 0.75
```
由于valueAtOneQuarter方法知道你会传入一个类型为`(x:Double) => Double`的函数，可以将上述代码改为:
```scala
valueAtOneQuarter( (x) => 3 * x )
```
或者
```scala
valueAtOneQuarter( x => 3 * x ) // 只有一个参数的函数　可以省略括号
```
如果参数在=>右侧只出现一次，可以使用 `_` 替换，因此进一步改写:
```scala
valueAtOneQuarter(3 * _)
```
### 5. 柯里化

柯里化是指将原来接受两个参数的函数变成一个新的接受一个参数的函数的过程．新的函数返回一个以原有第二个参数作为参数的函数．
```scala
def mul (x: Int, y: Int) = x * y
```
以下函数接受一个参数，生成另一个接受单个参数的函数:
```scala
def mulOneAtATime(x: Int) = (y: Int) => x * y
```
要计算两个数的乘积，需要调用:
```scala
mulOneAtATime(6)(7)
```
细分说明一下，mulOneAtATime(6)返回的是一个函数 `(y: Int) => 6 * y`．而这个函数又被应用到7，因此最终的结果为42．

Scala支持如下简写来定义柯里化函数:
```scala
def mulOneAtATime(x: Int) (y: Int) = x * y
```
我们可以看到多参数只是个虚饰，不是什么编程语言的特质．

### 6. 控制抽象

在Scala中，我们可以将一系列语句组成`不带参数也没有返回值`的函数．如下函数在线程中执行某段代码:
```scala
def runInThread(block: ()=>Unit){
  new Thread{
    override def run(){ block() }
  }.start()
}
```
上述函数为带函数参数的函数，函数参数类型为`()=>Unit`(表示没有参数也没有返回值)．但是如此一来，当你调用该函数时，需要写不美观的`()=>`:
```scala
runInThread{ () => println("Hello");Thread.sleep(10000);println("Bye");  }
```
要想在调用中省掉`()=>`，可以使用`换名调用`表示法：在参数声明和调用该函数参数的地方略去`()`，但保留`=`:
```scala
def runInThread(block: => Unit){ // (1)
  new Thread{
    override def run() { block } // (2)
  }.start()
}
```
这样，我们如下调用:
```scala
runInThread{ println("Hello");Thread.sleep(10000);println("Bye"); }
```
Scala程序员可以构建控制抽象:看上去像编程语言的关键字的函数．例如，下面我们定一个until语句，工作原理类似while，只不过把条件反过来用:
```scala
def until (condition: => Boolean) (block: => Unit) {
  if(!condition){
    block
    until (condition) (block)
  }
}
```
使用:
```scala
var x = 4
until (x == 0) {
  println(x)
  x = x -1
}
// 4
// 3
// 2
// 1
var x = 0
until (x == 0) {
  println(x)
  x = x -1
}
// 无输出
```
这样的函数参数有一个专业术语:换名调用参数．和常规的参数不同，函数被调用时，参数表达式不会被求值．毕竟，在调用until时，不希望`x == 0`被求值得到false．与之相反，表达式成为无参函数的函数体，而该函数被当做参数传递下去．
仔细看一下until函数的定义．注意它是柯里化的:函数首先处理掉condition，然后把block当做完全独立的另一个参数．如果没有柯里化，调用就会变成如下:
```scala
until (x == 0, {...})
```

### 7. return表达式

在Scala中，不需要使用return语句返回函数值．函数的返回值是函数体的值．不过，可以使用return来从一个匿名函数中返回值给包含这个匿名函数的带名函数．这对于抽象控制是很有用的:
```scala
def indexOf(str: String, ch: Char) : Int = {
  var i = 0;
  until (i == str.length){
    if(str(i) == ch) return i
    i += 1
  }
  return -1
}
```
在这里，匿名函数`{ if(str(i) == ch) return i; i += 1 }`被传递给until．当return表达式被执行时，包含它的带名函数indexOf终止并返回给定的值．如果要在带名函数中使用return的话，则需要给出其返回类型．例如上例中，编译器没法推断出它会返回Int，因此需要给出返回类型Int．


来源于： 快学Scala
