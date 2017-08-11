---
layout: post
title: "sFlow event handler"
description: "sFlow event handler介绍与使用"
category: SDN
tags: ["SDN", "sFlow"]
---

本文参考了blog.sflow.com上的两篇文章[1, 2]，由于没有找到介绍event handler的中文材料，只能自己整理了。

## 1.起因

在看到文献[3]之后，我对代码实现中的while很不爽。同时，仅会使用sFlow的API往往也不能满足需求。

在最近的学习中，发现了sFlow中的event handler，它可以通过js被用户定制，并能在event发生时执行。

## 2.通过js定制sFlow

根据sflow-rt/lib/js.jar，我们可以看出sFlow是通过Rhino完成java与js的互操作。

正如文献[1, 2]中所示，可以通过js定义sFlow的流（flow）、阈值（Threshold）、以及event handler。

例如，下面代码定义了tcp这个flow，elephant这个threshold。

当tcp流量超过elephant阈值时，执行event handler中的代码，获取flow的信息，并post到一个服务器中：

``` javascript
// Define large flow as greater than 1Mbits/sec for 1 second or longer
var bytes_per_second = 1000000/8;
var duration_seconds = 1;

setFlow('tcp',
    {keys:'ipsource,ipdestination,tcpsourceport,tcpdestinationport',
    value:'bytes', t:duration_seconds}
);

setThreshold('elephant',
    {metric:'tcp', value:bytes_per_second, byFlow:true, timeout:2}
);

setEventHandler(function(evt) {
    // Get flow informations
    var agent = evt.agent;
    logInfo(agent);         // not necessary

    // Sent POST request
    var http = require('http');
    var options = {         // use your server
        host: '127.0.0.1',
        path: '/EventLogic',
        port: '8080',
        method: 'POST'
    };
    callback = function(response) {
        var str = '';
        response.on('data', function(chunk) {
            str += chunk;
        });
        response.on('end', function() {
            logInfo(str);
        });
    }
    var req = http.request(options, callback);
    req.write(agent);
    req.end();
},['elephant']);
```

接着就是修改sFlow的start.sh来加载自定义的js脚本。我的js脚本位于path/to/sFlow/extras/test.js。

主要修改SCRIPTS参数。

``` sh
#!/bin/sh

HOME=`dirname $0`
cd $HOME

JAR="./lib/sflowrt.jar"
JVM_OPTS="-Xincgc -Xmx200m"
#RT_OPTS="-Dsflow.port=6343 -Dhttp.port=8008"
#SCRIPTS="-Dscript.file=init.js"
RT_OPTS="-Dopenflow.controller.start=yes -Dopenflow.controller.flushRules=no"
SCRIPTS="-Dscript.file=./extras/test.js"

exec java ${JVM_OPTS} ${RT_OPTS} ${SCRIPTS} -jar ${JAR}
```

由于我不太会js，还参考了文献[4]。

## 3.使用Redis

我们还可以将Redis与sFlow一同使用。

利用Redis实现网络状态的缓存，并通过event handler实现网络状态变化的推送。

由于sFlow通过Rhino解析js，直接调用Redis比较困难，我们可以采用Webdis[5]。

然而我并未对这种方案的性能进行测试，还是实验阶段。

## Reference

1.[Mininet integrated hybrid OpenFlow testbed](http://blog.sflow.com/2014/04/mininet-integrated-hybrid-openflow.html)

2.[Performance optimizing hybrid OpenFlow controller](http://blog.sflow.com/2014/03/performance-optimizing-hybrid-openflow.html)

3.[Performance aware software defined networking](http://blog.sflow.com/2013/01/performance-aware-software-defined.html)

4.[Http模块](http://javascript.ruanyifeng.com/nodejs/http.html)

5.[Webdis](https://github.com/nicolasff/webdis)
