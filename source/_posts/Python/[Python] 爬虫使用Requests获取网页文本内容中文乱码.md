
---
layout: post
author: sjf0115
title: Python 爬虫使用Requests获取网页文本内容中文乱码
date: 2017-12-05 09:46:20
tags:
  - Python

categories: Python
---

### 1. 问题

使用Requests去获取网页文本内容时，输出的中文出现乱码。

### 2. 乱码原因

爬取的网页编码与我们爬取编码方式不一致造成的。如果爬取的网页编码方式为`utf8`，而我们爬取后程序使用`ISO-8859-1`编码方式进行编码并输出，这会引起乱码。如果我们爬取后程序改用`utf8`编码方式，就不会造成乱码。

### 3. 乱码解决方案

#### 3.1 Content-Type

我们首先确定爬取的网页编码方式，编码方式往往可以从HTTP头(header)的`Content-Type`得出。

`Content-Type`，内容类型，一般是指网页中存在的`Content-Type`，用于定义网络文件的类型和网页的编码，决定浏览器将以什么形式、什么编码读取这个文件，这就是经常看到一些Asp网页点击的结果却是下载到的一个文件或一张图片的原因。如果未指定`ContentType`，默认为TEXT/HTML。`charset`决定了网页的编码方式，一般为`gb2312`、`utf-8`等

HTML语法格式:
```
<meta content="text/html; charset=utf-8" http-equiv="Content-Type"/>
```

```Python
station_request = requests.get("http://blog.csdn.net/sunnyyoona")
content_type = station_request.headers['content-type']
print content_type  # text/html; charset=utf-8
```

#### 3.2 chardet

如果上述方式没有编码信息，一般可以采用`chardet`等第三方网页编码智能识别工具识别:
```
pip install chardet
```

使用`chardet`可以很方便的实现文本内容的编码检测。虽然HTML页面有`charset`标签，但是有些时候并不准确，这时候我们可以使用`chardet`来进一步的判断:
```Python
raw_data = urllib.urlopen('http://blog.csdn.net/sunnyyoona').read()
print chardet.detect(raw_data)  # {'confidence': 0.99, 'encoding': 'utf-8'}

raw_data = urllib.urlopen('http://www.jb51.net').read()
print chardet.detect(raw_data)  # {'confidence': 0.99, 'encoding': 'GB2312'}
```
函数返回值为字典，有2个元素，一个是检测的可信度，另外一个就是检测到的编码。


#### 3.3 猜测编码

当你收到一个响应时，`Requests`会猜测响应(response)的编码方式，用于在你调用`Response.text`方法时，对响应进行解码。`Requests`首先在HTTP头部检测是否存在指定的编码方式，如果不存在，则会使用 `charadet`来尝试猜测编码方式。

只有当HTTP头部不存在明确指定的字符集，并且`Content-Type`头部字段包含`text`值之时，Requests才不去猜测编码方式。在这种情况下， `RFC 2616`指定默认字符集必须是`ISO-8859-1`。Requests遵从这一规范。如果你需要一种不同的编码方式，你可以手动设置`Response.encoding`属性，或使用原始的`Response.content`。

```Python
# 一等火车站
url = "https://baike.baidu.com/item/%E4%B8%80%E7%AD%89%E7%AB%99"
headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36'}
r = requests.get(url, headers=headers)
print r.headers['Content-Type']  # text/html
# 猜测的编码方式
print r.encoding  # ISO-8859-1
print r.text  # 出现乱码

raw_data = urllib.urlopen(url).read()
print chardet.detect(raw_data)  # {'confidence': 0.99, 'encoding': 'utf-8'}
```
如上所述，只有当HTTP头部不存在明确指定的字符集，并且`Content-Type`头部字段包含`text`值之时，Requests才不去猜测编码方式。直接使用`ISO-8859-1`编码方式。而使用`chardet`检测结果来看，网页编码方式与猜测的编码方式不一致，这就造成了结果输出的乱码。

#### 3.4 解决

你可以使用`r.encoding = xxx`来更改编码方式，这样`Requests`将在你调用`r.text`时使用`r.encoding`的新值，使用新的编码方式。下面示例使用`chardet`检测的编码方式解码网页:
```Python
# 一等火车站
url = "https://baike.baidu.com/item/%E4%B8%80%E7%AD%89%E7%AB%99"
headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36'}
r = requests.get(url, headers=headers)

# 检测编码
raw_data = urllib.urlopen(url).read()
charset = chardet.detect(raw_data)  # {'confidence': 0.99, 'encoding': 'utf-8'}
encoding = charset['encoding']
# 更改编码方式
r.encoding = encoding
print r.text  # 未出现乱码
```

参考:
```
http://docs.python-requests.org/en/latest/user/quickstart/#response-content
http://blog.csdn.net/a491057947/article/details/47292923
https://www.cnblogs.com/GUIDAO/p/6679574.html
```
