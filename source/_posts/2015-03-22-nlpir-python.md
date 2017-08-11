---
layout: post
title: "NLPIR Python"
description: "PyNLPIR allows you to easily segment Chinese text using NLPIR, one of the most widely-regarded Chinese text analyzers."
category: Natural Language Processing
tags: ["natural language", "python"]
---

## NLPIR

[NLPIR](http://www.nlpir.org/)，原名ICTCLAS，是北京理工大学[张华平](http://www.weibo.com/drkevinzhang)博士发布的自然语言处理与信息检索共享平台，是目前最广为人知的中文文本分析软件。

## 1.利用PyNLPIR处理中文文本

PyNLPIR是NLPIR/ICTCLAS中文分词软件的Python封装版。利用PyNLPIR可以简单地使用NLPIR对中文文本进行分词。

[官方文档](http://pynlpir.readthedocs.org/en/latest/installation.html)

### 1.1.用pip安装PyNLPIR

PyNLPIR可以运行在Python 2.7或3中。由于它包括NLPIR库文件，所以它只能运行在Windows或Linux操作系统中。

PyNLPIR可以通过三种方式安装：1.Pip，2.源文件，3.开发者版本。我这里采用最简单的pip进行安装。

`$ pip install pynlpir`

这行代码会从Python Package Index下载PyNLPIR，并安装在Python的site-packages目录。

### 1.2.Tutorial

有2种方式使用PyNLPIR：1.直接使用PyNLPIR提供的ctypes接口，2.使用PyNLPIR的helper functions。ctypes接口使用范围更广，而helper functions更加易用，但并不包括全部的NLPIR功能。我这里采用比较简单的helper functions。

#### 1.2.1.PyNLPIR Helper Functions
helper functions存放在PyNLPIR的__init__.py文件中，所以我们直接导入pynlpir就可以使用了。

``` python
import pynlpir
```

导入pynlpir后，需要调用open()让NLPIR打开data files并初始化API。

``` python
pynlpir.open()
```

默认情况，输入时unicode或UTF-8，如果想用别的编码方式（如GBK、BIG5），需要用encoding关键词。

``` python
pynlpir.open(encoding='big5')
```

初始化后我们就可以进行分词和文本分析了。首先进行分词。

``` python
s = "NLPIR分词系统前身为2000年发布的ICTCLAS词法分析系统，从2009年开始，为了和以前工作进行大的区隔，并推广NLPIR自然语言处理与信息检索共享平台，调整命名为NLPIR分词系统。"
pynlpir.segment(s)

# Sample output: [('NLPIR', 'noun'), ('分词', 'verb'), ('系统', 'noun'), ('前身', 'noun'), ('为', 'preposition'), ('2000年', 'time word'), ('发布', 'verb'), . . . ]
```

同时我们可以提取关键词。

``` python
pynlpir.get_key_words(s, weighted=True)

# Sample output: [('NLPIR', 2.08), ('系统', 1.74)]
```

当我们操作完毕后，可以关闭API。

``` python
pynlpir.close()
```

#### 1.2.2.Windows cmd
一切看起来都那么美好，然而问题来了。我在Win7 cmd中运行的结果看起来是这样的。

```
[(u'NLPIR', u'noun'), (u'\u5206\u8bcd', u'verb'), (u'\u7cfb\u7edf', u'noun')...]
```

这是由于python在输出的时候解码方式错误导致的。

这可以通过python的decode函数明确解码方法为，unicode-escape，来解决。

但是pynlpir.segment()输出的类型是list，没有decode函数，于是我们要先把它转换为str类型。

``` python
# Segmenting Text
s = "NLPIR分词系统前身为2000年发布的ICTCLAS词法分析系统，从2009年开始，为了和以前工作进行大的区隔，并推广NLPIR自然语言处理与信息检索共享平台，调整命名为NLPIR分词系统。"
out = str(pynlpir.segment(s)).decode("unicode-escape")
print out
```

Done.

## 2.关键词与交叉熵

NLPIR的关键词提取据说是基于期望交叉熵(Cross Entropy)实现的。

交叉熵是信息论中的概念，它是一种万能的Monte-Carlo技术，常用于稀有事件的仿真建模、多峰函数的最优化问题。交叉熵技术已用于解决经典的旅行商问题、背包问题、最短路问题、最大割问题等。例如，[A Tutorial on the Cross-Entropy Method](http://eprints.eemcs.utwente.nl/7716/01/fulltext.pdf)。

交叉熵算法的推导过程中又牵扯出来一个问题：如何求一个数学期望？常用的方法有这么几种：

+ 概率方法，比如Crude Monte-Carlo
+ 测度变换法change of measure
+ 偏微分方程的变量代换法
+ Green函数法
+ Fourier变换法

在实际中变量X服从的概率分布h往往是不知道的，人们会用g来近似地代替h（这本质上是一种函数估计）。有一种度量g和h相近程度的方法叫 Kullback-Leibler距离，又叫交叉熵。

$$D(g,h)=E_g log \frac{g(X)}{h(X)} = \frac{1}{N} \sum_{i=1}^{N} g(x_i) log \frac{g(x_i)}{h(x_i)}$$

通常选取g和h具有相同的概率分布类型（比如已知h是指数分布，那么就选g也是指数分布）----参数估计，只是pdf参数不一样（实际上h中的参数根本就是未知的）。

### 2.1.[基于期望交叉熵的特征项选择](http://www.cnblogs.com/zhangchaoyang/articles/2655785.html)

$$CE(\omega)=\sum_{i} p(c_i|\omega) log \frac{p(c_i|\omega)}{p(c_i)}$$

交叉熵反应了文本类别的概率分布与在出现了某个词条的情况下文本类别的概率分布之间的距离。词条的交叉熵越大，对文本类别分布影响也就越大。所以选CE最大的K个词条作为最终的特征项。
