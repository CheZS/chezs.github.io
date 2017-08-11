---
layout: post
title: "手动生成 autounattend.xml Password"
description: "base64对ucs2字符串编码，还加盐"
category: Windows
tags: ["Windows", "password"]
---

在手动生成autounattend.xml文件时，往往需要配置password参数。

把密码明文存在xml中显得不够安全，因此微软动了点小手脚。对password明文字符串首先加盐，再用ucs2编码，最后再转成base64.

举例（node.js）：

Administrator的密码是asdf。

``` javascript
var password = "asdf";                          // 明文
password = password + "AdministratorPassword";  // 加盐
var buffer = new Buffer(password, "ucs2");      // 用ucs2
var output = buffer.toString("base64");         // base64编码
```

对于其他user，修改盐的内容。

``` javascript
var password = "asdf";                          // 明文
password = password + "Password";               // 加盐
var buffer = new Buffer(password, "ucs2");      // 用ucs2
var output = buffer.toString("base64");         // base64编码
```
