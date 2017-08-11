---
layout: post
title: "sFlow入门"
description: "sFlow是一种以交换机端口为基本单元的数据流随机采样的流量监控工具"
category: SDN
tags: ["SDN", "sFlow"]
---

本文是参考了Milestone[1]，Liushy[2]，SDNLAB[3]，Mahout[4]以及sFlow-rt.com[5]整理的一份实验报告。

## 1.sFlow简介

sFlow是一种以交换机端口为基本单元的数据流随机采样的流量监控工具。

sFlow分为Agent和Collecter两部分。
Agent作为客户端，一般内嵌于网络转发设备（如交换机、路由器），通过获取本设备上的接口统计信息和数据信息，将信息封装成sFlow报文。
当sFlow报文缓冲区满或是在sFlow报文缓存时间（缓存时间为1秒）超时后，Agent会将sFlow报文发送到指定的Collector。
Collector作为远端服务器，负责对sFlow报文分析、汇总、生成流量报告。
OpenvSwitch支持sFlow，给我的实验带来了很大的方便。

sFlow可以对包进行较低比率的采样（典型情况：1000个包中采样1个），并只把包的头部封装为sFlow报文传给Collecter[4]。
因此资源的负载会比较低，并可以适应超大网络流量(如大于10Gbit/s)环境下的流量分析。

## 2.sFlow安装与配置

sFlow官方推荐的sFlow软件有sFlow-trend，sFlow-rt等，我选择了sFlow-rt。版本2.0-r1031。

1.安装jdk依赖

2.[下载官方压缩包](http://www.inmon.com/products/sFlow-RT.php)

3.解压并启动sFlow Collecter

``` bash
$ tar -zxvf sflow-rt.tar.gz
$ cd sflow/
$ ./start.sh
```

此时sFlow Collecter已经运行起来了。

## 3.sFlow示例

### 3.1.环境

| 设备    | IP            | 说明                        |
| --------|---------------|-----------------------------|
| eth0    | 192.168.11.6  | 连接外网网卡，也是Collecter |
| eth1    | 10.0.0.3      | 用于加入OVS生成网桥的网卡   |
| h1      | 10.0.0.1      | host1网卡                   |
| h2      | 10.0.0.2      | host2网卡                   |

### 3.2.配置

#### 3.2.1.启动mininet

``` bash
$ sudo mn
```

或者用Floodlight当控制器

``` bash
$ sudo mn --controller=remote,ip=192.168.11.6,port=6653 --switch ovsk,protocols=OpenFlow13
```

#### 3.2.2.配置OVS网桥

为了通过本地网卡8008端口获取mininet中的数据，需要让eth1加入到OVS生成的网桥，进而mininet中创建的OVS和服务器本地网卡相连。

** 此处注意：将连接外网的eth0加入网桥后就不能上网了。 **

``` bash
$ sudo ovs-vsctl add-port s1 eth1
```

配置s1的IP，使OVS可以作为Agent和Collecter通信。

``` bash
$ sudo ifconfig eth1 10.0.0.3 netmask 255.255.255.0
```

#### 3.2.3.开启OVS的sFlow功能

``` bash
$ sudo ovs-vsctl -- --id=@sflow_id create sFlow agent=s1 target=\"192.168.11.6:6343\" header=128 sampling=64 polling=1 -- set bridge s1 sflow=@sflow_id
```

参数说明：

agent参数值为Agent的网卡(s1)，target参数值为Collecter的IP:port[6343]。

header为允许拷贝的最大字节数(128)，sampling为采样频率(64个包中采样1个)，polling为sFlow报文缓冲时间(1s)。

bridge为开启sFlow的网桥。

#### 3.2.4.查看配置是否生效

``` bash
$ sudo ovs-vsctl list sflow
```

![OVS配置sFlow](/images/20151103/OVSList.jpg)

### 3.3.效果

打开http://192.168.11.6:8008 ，可以查看对应的信息。可以通过mininet的命令产生流量。

例如，h1泛洪模式ping h2

``` bash
mininet> h1 ping -f h2
```

![sFlow-RT GUI](/images/20151103/sFlow.jpg)

## 4.API

sFlow支持RESTful API。常见的形式如同：

### 4.1.定义地址组address groups

地址组用来分类不同的流量(traffic)。这里定义了external和internal两种地址组。

``` bash
$ curl -H "Content-Type:application/json" -X PUT --data "{external:['0.0.0.0/0']}" http://localhost:8008/group/external/json
$ curl -H "Content-Type:application/json" -X PUT --data "{internal:['10.0.0.0/8']}" http://localhost:8008/group/internal/json
```

### 4.2.定义流flow

通过包的属性(keys)来定义流。流根据属性把不同的包分组，通过value确定单位(bytes, frames, requests, duration)，通过filter选择特定的traffic。最后URL中的incoming为flow的Name。此时会一同定义名为incoming的metric。

``` bash
$ curl -H "Content-Type:application/json" -X PUT --data "{keys:'ipsource,ipdestination', value:'frames', filter:'group:ipsource:external=external&group:ipdestination:internal=internal'}" http://localhost:8008/flow/incoming/json
```

**注意，filter中的external和internal要一致。**

### 4.3.定义阈值threshold

``` bash
$ curl -H "Content-Type:application/json" -X PUT --data "{metric:'incoming', value:1000}" http://localhost:8008/threshold/incoming/json
```

### 4.4.接收阈值事件event

``` bash
$ curl "http://localhost:8008/events/json?eventID=4&timeout=60"
```

### 4.5.监测流

``` bash
$ curl "http://localhost:8008/metric/192.168.11.6/4.incoming/json"
```

## Reference
1.[Milestone](http://www.muzixing.com/pages/2014/11/21/sflowru-men-chu-she.html)

2.[Liushy](http://liushy.com/2015/01/27/sflow-ddos/)

3.[SDNLAB](http://www.sdnlab.com/3760.html)

4.[Mahout: Low-overhead datacenter traffic management using end-host-based elephant detection](http://shiftleft.com/mirrors/www.hpl.hp.com/personal/Praveen_Yalagandula/papers/INFOCOM11.pdf)

5.[sFlow API](http://sflow-rt.com/reference.php)
