---
layout: post
author: sjf0115
title: Storm UI REST API
date: 2019-08-02 21:33:01
tags:
  - Storm
  - Storm 基础

categories: Storm
permalink: storm-ui-rest-api
---

### 1. 简介

Storm UI 守护进程提供了 REST API, 允许我们与 Storm 集群进行交互, 其中包括查看指标数据，配置信息以及启动或停止拓扑的管理操作。REST API 结果以 JSON 形式返回。

### 2. 用法

REST API 是 Storm UI 守护进程（由 storm ui 启动）的一部分，因此与 Storm UI 守护进程在同一主机和端口上运行。通过 `ui.port` 参数来配置端口，默认为 8080。

> UI 守护进程通常与 Nimbus 守护进程在同一主机上运行。

API 基本 URL 形式如下:
```
http://<ui-host>:<ui-port>/api/v1/...
```
我们可以使用 curl 等工具来操作 REST API:
```
# 请求集群配置
# 注意: 假设 ui.port 配置的为默认值 8080
$ curl http://<ui-host>:8080/api/v1/cluster/configuration
```

### 3. API介绍

#### 3.1 GET 操作

##### 3.1.1 /api/v1/cluster/configuration

使用如下 API 返回集群配置：
```
.../api/v1/cluster/configuration
```
返回结果如下:
```json
{
  "dev.zookeeper.path": "/tmp/dev-storm-zookeeper",
  "topology.tick.tuple.freq.secs": null,
  "topology.builtin.metrics.bucket.size.secs": 60,
  "topology.fall.back.on.java.serialization": true,
  "topology.max.error.report.per.interval": 5,
  "zmq.linger.millis": 5000,
  "topology.skip.missing.kryo.registrations": false,
  "storm.messaging.netty.client_worker_threads": 1,
  "ui.childopts": "-Xmx768m",
  "storm.zookeeper.session.timeout": 20000,
  "nimbus.reassign": true,
  "topology.trident.batch.emit.interval.millis": 500,
  "storm.messaging.netty.flush.check.interval.ms": 10,
  "nimbus.monitor.freq.secs": 10,
  "logviewer.childopts": "-Xmx128m",
  "java.library.path":"/usr/local/lib:/opt/local/lib:/usr/lib",
  "topology.executor.send.buffer.size": 1024,
  ...
}
```
##### 3.1.2 /api/v1/cluster/summary

使用如下 API 返回集群摘要信息，例如 nimbus 正常运行时间或 Supervisors 数量:
```
.../api/v1/cluster/summary
```
返回字段如下:

|Field  |Value|Description
|---	|---	|---
|stormVersion|String| Storm version|
|supervisors|Integer| Number of supervisors running|
|topologies| Integer| Number of topologies running|
|slotsTotal| Integer|Total number of available worker slots|
|slotsUsed| Integer| Number of worker slots used|
|slotsFree| Integer |Number of worker slots available|
|executorsTotal| Integer |Total number of executors|
|tasksTotal| Integer |Total tasks|
|schedulerDisplayResource| Boolean | Whether to display scheduler resource information|
|totalMem| Double | The total amount of memory in the cluster in MB|
|totalCpu| Double | The total amount of CPU in the cluster|
|availMem| Double | The amount of available memory in the cluster in MB|
|availCpu| Double | The amount of available cpu in the cluster|
|memAssignedPercentUtil| Double | The percent utilization of assigned memory resources in cluster|
|cpuAssignedPercentUtil| Double | The percent utilization of assigned CPU resources in cluster|

返回结果如下:
```json
{
 "stormVersion": "0.9.2-incubating-SNAPSHOT",
 "supervisors": 1,
 "slotsTotal": 4,
 "slotsUsed": 3,
 "slotsFree": 1,
 "executorsTotal": 28,
 "tasksTotal": 28,
 "schedulerDisplayResource": true,
 "totalMem": 4096.0,
 "totalCpu": 400.0,
 "availMem": 1024.0,
 "availCPU": 250.0,
 "memAssignedPercentUtil": 75.0,
 "cpuAssignedPercentUtil": 37.5
}
```
##### 3.1.3 /api/v1/supervisor/summary

使用如下 API 返回所有 Supervisor 的摘要信息:
```
.../api/v1/supervisor/summary
```
返回字段如下:

|Field  |Value|Description|
|---	|---	|---
|id| String | Supervisor's id|
|host| String| Supervisor's host name|
|uptime| String| Shows how long the supervisor is running|
|uptimeSeconds| Integer| Shows how long the supervisor is running in seconds|
|slotsTotal| Integer| Total number of available worker slots for this supervisor|
|slotsUsed| Integer| Number of worker slots used on this supervisor|
|schedulerDisplayResource| Boolean | Whether to display scheduler resource information|
|totalMem| Double| Total memory capacity on this supervisor|
|totalCpu| Double| Total CPU capacity on this supervisor|
|usedMem| Double| Used memory capacity on this supervisor|
|usedCpu| Double| Used CPU capacity on this supervisor|

返回结果如下:
```json
{
  "supervisors": [
    {
      "id": "0b879808-2a26-442b-8f7d-23101e0c3696",
      "host": "10.11.1.7",
      "uptime": "5m 58s",
      "uptimeSeconds": 358,
      "slotsTotal": 4,
      "slotsUsed": 3,
      "totalMem": 3000,
      "totalCpu": 400,
      "usedMem": 1280,
      "usedCPU": 160,
      ...
    }
  ],
  "schedulerDisplayResource": false,
  "logviewerPort": 8000
}
```
##### 3.1.4 /api/v1/nimbus/summary

使用如下 API 返回所有 Nimbus 主机的摘要信息:
```
.../api/v1/nimbus/summary
```
返回字段如下:

|Field  |Value|Description|
|---	|---	|---
|host| String | Nimbus' host name|
|port| int| Nimbus' port number|
|status| String| Possible values are Leader, Not a Leader, Dead|
|nimbusUpTime| String| Shows since how long the nimbus has been running|
|nimbusUpTimeSeconds| String| Shows since how long the nimbus has been running in seconds|
|nimbusLogLink| String| Logviewer url to view the nimbus.log|
|version| String| Version of storm this nimbus host is running|

返回结果如下:
```json
{
  "nimbuses": [
    {
      "host": "192.168.202.1",
      "port": 6627,
      "nimbusLogLink": "http:\/\/192.168.202.1:8000\/log?file=nimbus.log",
      "status": Leader,
      "version": "0.10.0-SNAPSHOT",
      "nimbusUpTime": "3m 33s",
      "nimbusUpTimeSeconds": "213"
    }
  ]
}
```
##### 3.1.5 /api/v1/history/summary

使用如下 API 返回当前用户提交运行过的拓扑ID列表:
```
.../api/v1/history/summary
```
返回字段如下:

|Field  |Value | Description|
|---	|---	|---
|topo-history| List| List of Topologies' IDs|

返回结果如下:
```json
{
  "topo-history": [
    "Lark-video-recommend-topology-prod-4-1563888740",
    "Lark-video-recommend-topology-prod-1-1560338080",
    "Lark-video-recommend-topology-prod-2-1562916038",
    "Lark-video-recommend-topology-prod-3-1563883103"
  ]
}
```
##### 3.1.6 /api/v1/supervisor

使用如下 API 查询特定ID的 Supervisor 或某一台主机上运行的所有 Supervisor 的摘要信息：
```
.../api/v1/supervisor
```
Example:
```
# 根据Host查询Supervisor
http://<ui-host>:<ui-port>/api/v1/supervisor?host=xxx
# 根据Id查询Supervisor
http://<ui-host>:<ui-port>/api/v1/supervisor?id=3d175f35-e427-4ede-be4a-0bccec80ea36
```
请求参数:

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String. Supervisor id | If specified, respond with the supervisor and worker stats with id. Note that when id is specified, the host argument is ignored. |
|host      |String. Host name| If specified, respond with all supervisors and worker stats in the host (normally just one)|
|sys       |String. Values 1 or 0. Default value 0| Controls including sys stats part of the response|


返回字段如下:

|Field  |Value|Description|
|---	|---	|---
|supervisors| Array| Array of supervisor summaries|
|workers| Array| Array of worker summaries |
|schedulerDisplayResource| Boolean | Whether to display scheduler resource information|

根据如下字段指定 Supervisor:

|Field  |Value|Description|
|---	|---	|---
|id| String | Supervisor's id|
|host| String| Supervisor's host name|
|uptime| String| Shows how long the supervisor is running|
|uptimeSeconds| Integer| Shows how long the supervisor is running in seconds|
|slotsTotal| Integer| Total number of worker slots for this supervisor|
|slotsUsed| Integer| Number of worker slots used on this supervisor|
|schedulerDisplayResource| Boolean | Whether to display scheduler resource information|
|totalMem| Double| Total memory capacity on this supervisor|
|totalCpu| Double| Total CPU capacity on this supervisor|
|usedMem| Double| Used memory capacity on this supervisor|
|usedCpu| Double| Used CPU capacity on this supervisor|

根据如下字段指定 worker:

|Field  |Value  |Description|
|-------|-------|-----------|
|supervisorId | String| Supervisor's id|
|host | String | Worker's host name|
|port | Integer | Worker's port|
|topologyId | String | Topology Id|
|topologyName | String | Topology Name|
|executorsTotal | Integer | Number of executors used by the topology in this worker|
|assignedMemOnHeap | Double | Assigned On-Heap Memory by Scheduler (MB)|
|assignedMemOffHeap | Double | Assigned Off-Heap Memory by Scheduler (MB)|
|assignedCpu | Number | Assigned CPU by Scheduler (%)|
|componentNumTasks | Dictionary | Components -> # of executing tasks|
|uptime| String| Shows how long the worker is running|
|uptimeSeconds| Integer| Shows how long the worker is running in seconds|
|workerLogLink | String | Link to worker log viewer page|

返回结果如下:
```json
{
    "supervisors": [
      {
        "totalMem": 4096.0,
        "host":"192.168.10.237",
        "id":"bdfe8eff-f1d8-4bce-81f5-9d3ae1bf432e",
        "uptime":"7m 8s",
        "totalCpu":400.0,
        "usedCpu":495.0,
        "usedMem":3432.0,
        "slotsUsed":2,
        "version":"0.10.1",
        "slotsTotal":4,
        "uptimeSeconds":428
    }],
    "schedulerDisplayResource":true,
    "workers":[{
        "topologyName":"ras",
        "topologyId":"ras-4-1460229987",
        "host":"192.168.10.237",
        "supervisorId":"bdfe8eff-f1d8-4bce-81f5-9d3ae1bf432e",
        "assignedMemOnHeap":704.0,
        "uptime":"2m 47s",
        "uptimeSeconds":167,
        "port":6707,
        "workerLogLink":"http:\/\/host:8000\/log?file=ras-4-1460229987%2F6707%2Fworker.log",
        "componentNumTasks": {
            "word":5
        },
        "executorsTotal":8,
        "assignedCpu":130.0,
        "assignedMemOffHeap":80.0
    },
    {
        "topologyName":"ras",
        "topologyId":"ras-4-1460229987",
        "host":"192.168.10.237",
        "supervisorId":"bdfe8eff-f1d8-4bce-81f5-9d3ae1bf432e",
        "assignedMemOnHeap":904.0,
        "uptime":"2m 53s",
        "port":6706,
        "workerLogLink":"http:\/\/host:8000\/log?file=ras-4-1460229987%2F6706%2Fworker.log",
        "componentNumTasks":{
            "exclaim2":2,
            "exclaim1":3,
            "word":5
        },
        "executorsTotal":10,
        "uptimeSeconds":173,
        "assignedCpu":165.0,
        "assignedMemOffHeap":80.0
    }]
}
```
##### 3.1.7 /api/v1/topology/summary

使用如下 API 返回所有拓扑的信息：
```
.../api/v1/topology/summary
```

返回字段如下：

|Field  |Value | Description|
|---	|---	|---
|id| String| Topology Id|
|name| String| Topology Name|
|status| String| Topology Status|
|uptime| String|  Shows how long the topology is running|
|uptimeSeconds| Integer|  Shows how long the topology is running in seconds|
|tasksTotal| Integer |Total number of tasks for this topology|
|workersTotal| Integer |Number of workers used for this topology|
|executorsTotal| Integer |Number of executors used for this topology|
|replicationCount| Integer |Number of nimbus hosts on which this topology code is replicated|
|requestedMemOnHeap| Double|Requested On-Heap Memory by User (MB)
|requestedMemOffHeap| Double|Requested Off-Heap Memory by User (MB)|
|requestedTotalMem| Double|Requested Total Memory by User (MB)|
|requestedCpu| Double|Requested CPU by User (%)|
|assignedMemOnHeap| Double|Assigned On-Heap Memory by Scheduler (MB)|
|assignedMemOffHeap| Double|Assigned Off-Heap Memory by Scheduler (MB)|
|assignedTotalMem| Double|Assigned Total Memory by Scheduler (MB)|
|assignedCpu| Double|Assigned CPU by Scheduler (%)|
|schedulerDisplayResource| Boolean | Whether to display scheduler resource information|

返回结果如下：
```json
{
    "topologies": [
        {
            "id": "WordCount3-1-1402960825",
            "name": "WordCount3",
            "status": "ACTIVE",
            "uptime": "6m 5s",
            "uptimeSeconds": 365,
            "tasksTotal": 28,
            "workersTotal": 3,
            "executorsTotal": 28,
            "replicationCount": 1,
            "requestedMemOnHeap": 640,
            "requestedMemOffHeap": 128,
            "requestedTotalMem": 768,
            "requestedCpu": 80,
            "assignedMemOnHeap": 640,
            "assignedMemOffHeap": 128,
            "assignedTotalMem": 768,
            "assignedCpu": 80
        }
    ],
    "schedulerDisplayResource": true
}
```
##### 3.1.8 /api/v1/topology-workers/\<id\>

使用如下 API 返回 Id 指定拓扑的 Worker 信息：
```
.../api/v1/topology-workers/<id>
```

返回字段如下：

|Field  |Value | Description|
|---	|---	|---
|hostPortList| List| Workers' information for a topology|
|name| Integer| Logviewer Port|

返回结果如下：
```json
{
  "hostPortList": [
    {
      "host": "192.168.202.2",
      "port": 6701
    },
    {
      "host": "192.168.202.2",
      "port": 6702
    },
    {
      "host": "192.168.202.3",
      "port": 6700
    }
  ],
  "logviewerPort": 8000
}
```
##### 3.1.9 /api/v1/topology/\<id\>

使用如下 API 返回 Id 指定拓扑信息与统计指标：
```
.../api/v1/topology/<id>
```
请求参数字段如下：

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |
|window    |String. Default value :all-time| Window duration for metrics in seconds|
|sys       |String. Values 1 or 0. Default value 0| Controls including sys stats part of the response|

返回字段如下：

|Field  |Value |Description|
|---	|---	|---
|id| String| Topology Id|
|name| String |Topology Name|
|uptime| String |How long the topology has been running|
|uptimeSeconds| Integer |How long the topology has been running in seconds|
|status| String |Current status of the topology, e.g. "ACTIVE"|
|tasksTotal| Integer |Total number of tasks for this topology|
|workersTotal| Integer |Number of workers used for this topology|
|executorsTotal| Integer |Number of executors used for this topology|
|msgTimeout| Integer | Number of seconds a tuple has before the spout considers it failed |
|windowHint| String | window param value in "hh mm ss" format. Default value is "All Time"|
|schedulerDisplayResource| Boolean | Whether to display scheduler resource information|
|replicationCount| Integer |Number of nimbus hosts on which this topology code is replicated|
|debug| Boolean | If debug is enabled for the topology|
|samplingPct| Double| Controls downsampling of events before they are sent to event log (percentage)|
|assignedMemOnHeap| Double|Assigned On-Heap Memory by Scheduler (MB)
|assignedMemOffHeap| Double|Assigned Off-Heap Memory by Scheduler (MB)|
|assignedTotalMem| Double|Assigned Off-Heap + On-Heap Memory by Scheduler(MB)|
|assignedCpu| Double|Assigned CPU by Scheduler(%)|
|requestedMemOnHeap| Double|Requested On-Heap Memory by User (MB)
|requestedMemOffHeap| Double|Requested Off-Heap Memory by User (MB)|
|requestedCpu| Double|Requested CPU by User (%)|
|topologyStats| Array | Array of all the topology related stats per time window|
|topologyStats.windowPretty| String |Duration passed in HH:MM:SS format|
|topologyStats.window| String |User requested time window for metrics|
|topologyStats.emitted| Long |Number of messages emitted in given window|
|topologyStats.trasferred| Long |Number messages transferred in given window|
|topologyStats.completeLatency| String (double value returned in String format) |Total latency for processing the message|
|topologyStats.acked| Long |Number of messages acked in given window|
|topologyStats.failed| Long |Number of messages failed in given window|
|workers| Array | Array of workers in topology|
|workers.supervisorId | String| Supervisor's id|
|workers.host | String | Worker's host name|
|workers.port | Integer | Worker's port|
|workers.topologyId | String | Topology Id|
|workers.topologyName | String | Topology Name|
|workers.executorsTotal | Integer | Number of executors used by the topology in this worker|
|workers.assignedMemOnHeap | Double | Assigned On-Heap Memory by Scheduler (MB)|
|workers.assignedMemOffHeap | Double | Assigned Off-Heap Memory by Scheduler (MB)|
|workers.assignedCpu | Number | Assigned CPU by Scheduler (%)|
|workers.componentNumTasks | Dictionary | Components -> # of executing tasks|
|workers.uptime| String| Shows how long the worker is running|
|workers.uptimeSeconds| Integer| Shows how long the worker is running in seconds|
|workers.workerLogLink | String | Link to worker log viewer page|
|spouts| Array | Array of all the spout components in the topology|
|spouts.spoutId| String |Spout id|
|spouts.executors| Integer |Number of executors for the spout|
|spouts.emitted| Long |Number of messages emitted in given window |
|spouts.completeLatency| String (double value returned in String format) |Total latency for processing the message|
|spouts.transferred| Long |Total number of messages  transferred in given window|
|spouts.tasks| Integer |Total number of tasks for the spout|
|spouts.lastError| String |Shows the last error happened in a spout|
|spouts.errorLapsedSecs| Integer | Number of seconds elapsed since that last error happened in a spout|
|spouts.errorWorkerLogLink| String | Link to the worker log that reported the exception |
|spouts.acked| Long |Number of messages acked|
|spouts.failed| Long |Number of messages failed|
|spouts.requestedMemOnHeap| Double|Requested On-Heap Memory by User (MB)
|spouts.requestedMemOffHeap| Double|Requested Off-Heap Memory by User (MB)|
|spouts.requestedCpu| Double|Requested CPU by User (%)|
|bolts| Array | Array of bolt components in the topology|
|bolts.boltId| String |Bolt id|
|bolts.capacity| String (double value returned in String format) |This value indicates number of messages executed * average execute latency / time window|
|bolts.processLatency| String (double value returned in String format)  |Average time of the bolt to ack a message after it was received|
|bolts.executeLatency| String (double value returned in String format) |Average time to run the execute method of the bolt|
|bolts.executors| Integer |Number of executor tasks in the bolt component|
|bolts.tasks| Integer |Number of instances of bolt|
|bolts.acked| Long |Number of tuples acked by the bolt|
|bolts.failed| Long |Number of tuples failed by the bolt|
|bolts.lastError| String |Shows the last error occurred in the bolt|
|bolts.errorLapsedSecs| Integer |Number of seconds elapsed since that last error happened in a bolt|
|bolts.errorWorkerLogLink| String | Link to the worker log that reported the exception |
|bolts.emitted| Long |Number of tuples emitted|
|bolts.requestedMemOnHeap| Double|Requested On-Heap Memory by User (MB)
|bolts.requestedMemOffHeap| Double|Requested Off-Heap Memory by User (MB)|
|bolts.requestedCpu| Double|Requested CPU by User (%)|

Example:
```no-highlight
 1. http://<ui.host>:<ui.port>/api/v1/topology/WordCount3-1-1402960825
 2. http://<ui.host>:<ui.port>/api/v1/topology/WordCount3-1-1402960825?sys=1
 3. http://<ui.host>:<ui.port>/api/v1/topology/WordCount3-1-1402960825?window=600
```

返回结果如下:
```json
{
  "name": "WordCount3",
  "id": "WordCount3-1-1402960825",
  "workersTotal": 3,
  "window": "600",
  "status": "ACTIVE",
  "tasksTotal": 28,
  "executorsTotal": 28,
  "uptime": "29m 19s",
  "uptimeSeconds": 1759,
  "msgTimeout": 30,
  "windowHint": "10m 0s",
  "schedulerDisplayResource": true,
  "workers": [
    {
      "topologyName": "WordCount3",
      "topologyId": "WordCount3-1-1402960825",
      "host": "my-host",
      "supervisorId": "9124ca9a-42e8-481e-9bf3-a041d9595430",
      "assignedMemOnHeap": 1452.0,
      "uptime": "27m 26s",
      "port": 6702,
      "workerLogLink": "logs",
      "componentNumTasks": {
        "spout": 2,
        "count": 3,
        "split": 10
      },
      "executorsTotal": 15,
      "uptimeSeconds": 1646,
      "assignedCpu": 260.0,
      "assignedMemOffHeap": 160.0
    }
  ]"topologyStats": [
    {
      "windowPretty": "10m 0s",
      "window": "600",
      "emitted": 397960,
      "transferred": 213380,
      "completeLatency": "0.000",
      "acked": 213460,
      "failed": 0
    },
    {
      "windowPretty": "3h 0m 0s",
      "window": "10800",
      "emitted": 1190260,
      "transferred": 638260,
      "completeLatency": "0.000",
      "acked": 638280,
      "failed": 0
    },
    {
      "windowPretty": "1d 0h 0m 0s",
      "window": "86400",
      "emitted": 1190260,
      "transferred": 638260,
      "completeLatency": "0.000",
      "acked": 638280,
      "failed": 0
    },
    {
      "windowPretty": "All time",
      "window": ":all-time",
      "emitted": 1190260,
      "transferred": 638260,
      "completeLatency": "0.000",
      "acked": 638280,
      "failed": 0
    }
  ],
  "workers": [
    {
      "topologyName": "WordCount3",
      "topologyId": "WordCount3-1-1402960825",
      "host": "192.168.10.237",
      "supervisorId": "bdfe8eff-f1d8-4bce-81f5-9d3ae1bf432e-169.254.129.212",
      "uptime": "2m 47s",
      "uptimeSeconds": 167,
      "port": 6707,
      "workerLogLink": "http:\/\/192.168.10.237:8000\/log?file=WordCount3-1-1402960825%2F6707%2Fworker.log",
      "componentNumTasks": {
        "spout": 5
      },
      "executorsTotal": 8,
      "assignedMemOnHeap": 704.0,
      "assignedCpu": 130.0,
      "assignedMemOffHeap": 80.0
    }
  ],
  "spouts": [
    {
      "executors": 5,
      "emitted": 28880,
      "completeLatency": "0.000",
      "transferred": 28880,
      "acked": 0,
      "spoutId": "spout",
      "tasks": 5,
      "lastError": "",
      "errorLapsedSecs": null,
      "failed": 0
    }
  ],
  "bolts": [
    {
      "executors": 12,
      "emitted": 184580,
      "transferred": 0,
      "acked": 184640,
      "executeLatency": "0.048",
      "tasks": 12,
      "executed": 184620,
      "processLatency": "0.043",
      "boltId": "count",
      "lastError": "",
      "errorLapsedSecs": null,
      "capacity": "0.003",
      "failed": 0
    },
    {
      "executors": 8,
      "emitted": 184500,
      "transferred": 184500,
      "acked": 28820,
      "executeLatency": "0.024",
      "tasks": 8,
      "executed": 28780,
      "processLatency": "2.112",
      "boltId": "split",
      "lastError": "",
      "errorLapsedSecs": null,
      "capacity": "0.000",
      "failed": 0
    }
  ],
  "configuration": {
    "storm.id": "WordCount3-1-1402960825",
    "dev.zookeeper.path": "/tmp/dev-storm-zookeeper",
    "topology.tick.tuple.freq.secs": null,
    "topology.builtin.metrics.bucket.size.secs": 60,
    "topology.fall.back.on.java.serialization": true,
    "topology.max.error.report.per.interval": 5,
    "zmq.linger.millis": 5000,
    "topology.skip.missing.kryo.registrations": false,
    "storm.messaging.netty.client_worker_threads": 1,
    "ui.childopts": "-Xmx768m",
    "storm.zookeeper.session.timeout": 20000,
    "nimbus.reassign": true,
    "topology.trident.batch.emit.interval.millis": 500,
    "storm.messaging.netty.flush.check.interval.ms": 10,
    "nimbus.monitor.freq.secs": 10,
    "logviewer.childopts": "-Xmx128m",
    "java.library.path": "/usr/local/lib:/opt/local/lib:/usr/lib",
    "topology.executor.send.buffer.size": 1024,
    "storm.local.dir": "storm-local",
    "storm.messaging.netty.buffer_size": 5242880,
    "supervisor.worker.start.timeout.secs": 120,
    "topology.enable.message.timeouts": true,
    "nimbus.cleanup.inbox.freq.secs": 600,
    "nimbus.inbox.jar.expiration.secs": 3600,
    "drpc.worker.threads": 64,
    "topology.worker.shared.thread.pool.size": 4,
    "nimbus.seeds": [
      "hw10843.local"
    ],
    "storm.messaging.netty.min_wait_ms": 100,
    "storm.zookeeper.port": 2181,
    "transactional.zookeeper.port": null,
    "topology.executor.receive.buffer.size": 1024,
    "transactional.zookeeper.servers": null,
    "storm.zookeeper.root": "/storm",
    "storm.zookeeper.retry.intervalceiling.millis": 30000,
    "supervisor.enable": true,
    "storm.messaging.netty.server_worker_threads": 1
  },
  "replicationCount": 1
}
```
##### 3.1.10 /api/v1/topology/\<id\>/metrics

使用如下 API 返回 Id 指定拓扑每个组件的详细度量指标：
```
.../api/v1/topology/<id>/metrics
```
请求参数如下：

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |
|window    |String. Default value :all-time| window duration for metrics in seconds|
|sys       |String. Values 1 or 0. Default value 0| Controls including sys stats part of the response|

返回字段如下：

|Field  |Value |Description|
|---	|---	|---
|window    |String. Default value ":all-time" | window duration for metrics in seconds|
 |windowHint| String | window param value in "hh mm ss" format. Default value is "All Time"|
|spouts| Array | Array of all the spout components in the topology|
|spouts.id| String |Spout id|
|spouts.emitted| Array | Array of all the output streams this spout emits messages |
|spouts.emitted.stream_id| String | Stream id for this stream |
|spouts.emitted.value| Long | Number of messages emitted in given window|
|spouts.transferred | Array | Array of all the output streams this spout transfers messages |
|spouts.transferred.stream_id| String | Stream id for this stream |
|spouts.transferred.value| Long |Number messages transferred in given window|
|spouts.acked| Array | Array of all the output streams this spout receives ack of messages |
|spouts.acked.stream_id| String | Stream id for this stream |
|spouts.acked.value| Long |Number of messages acked in given window|
|spouts.failed| Array | Array of all the output streams this spout receives fail of messages |
|spouts.failed.stream_id| String | Stream id for this stream |
|spouts.failed.value| Long |Number of messages failed in given window|
|spouts.complete_ms_avg| Array | Array of all the output streams this spout receives ack of messages |
|spouts.complete_ms_avg.stream_id| String | Stream id for this stream |
|spouts.complete_ms_avg.value| String (double value returned in String format) | Total latency for processing the message|
|bolts| Array | Array of all the bolt components in the topology|
|bolts.id| String |Bolt id|
|bolts.emitted| Array | Array of all the output streams this bolt emits messages |
|bolts.emitted.stream_id| String | Stream id for this stream |
|bolts.emitted.value| Long | Number of messages emitted in given window|
|bolts.transferred | Array | Array of all the output streams this bolt transfers messages |
|bolts.transferred.stream_id| String | Stream id for this stream |
|bolts.transferred.value| Long |Number messages transferred in given window|
|bolts.acked| Array | Array of all the input streams this bolt acknowledges of messages |
|bolts.acked.component_id| String | Component id for this stream |
|bolts.acked.stream_id| String | Stream id for this stream |
|bolts.acked.value| Long |Number of messages acked in given window|
|bolts.failed| Array | Array of all the input streams this bolt receives fail of messages |
|bolts.failed.component_id| String | Component id for this stream |
|bolts.failed.stream_id| String | Stream id for this stream |
|bolts.failed.value| Long |Number of messages failed in given window|
|bolts.process_ms_avg| Array | Array of all the input streams this spout acks messages |
|bolts.process_ms_avg.component_id| String | Component id for this stream |
|bolts.process_ms_avg.stream_id| String | Stream id for this stream |
|bolts.process_ms_avg.value| String (double value returned in String format) |Average time of the bolt to ack a message after it was received|
|bolts.executed| Array | Array of all the input streams this bolt executes messages |
|bolts.executed.component_id| String | Component id for this stream |
|bolts.executed.stream_id| String | Stream id for this stream |
|bolts.executed.value| Long |Number of messages executed in given window|
|bolts.executed_ms_avg| Array | Array of all the output streams this spout receives ack of messages |
|bolts.executed_ms_avg.component_id| String | Component id for this stream |
|bolts.executed_ms_avg.stream_id| String | Stream id for this stream |
|bolts.executed_ms_avg.value| String (double value returned in String format) | Average time to run the execute method of the bolt|

Example：
```no-highlight
1. http://<ui.host>:<ui.port>/api/v1/topology/WordCount3-1-1402960825/metrics
2. http://<ui.host>:<ui.port>/api/v1/topology/WordCount3-1-1402960825/metrics?sys=1
3. http://<ui.host>:<ui.port>/api/v1/topology/WordCount3-1-1402960825/metrics?window=600
```
返回结果如下：
```json
{
  "window": ":all-time",
  "window-hint": "All time",
  "spouts": [
    {
      "id": "spout",
      "emitted": [
        {
          "stream_id": "__metrics",
          "value": 20
        },
        {
          "stream_id": "default",
          "value": 17350280
        },
        {
          "stream_id": "__ack_init",
          "value": 17328160
        },
        {
          "stream_id": "__system",
          "value": 20
        }
      ],
      "transferred": [
        {
          "stream_id": "__metrics",
          "value": 20
        },
        {
          "stream_id": "default",
          "value": 17350280
        },
        {
          "stream_id": "__ack_init",
          "value": 17328160
        },
        {
          "stream_id": "__system",
          "value": 0
        }
      ],
      "acked": [
        {
          "stream_id": "default",
          "value": 17339180
        }
      ],
      "failed": [

      ],
      "complete_ms_avg": [
        {
          "stream_id": "default",
          "value": "920.497"
        }
      ]
    }
  ],
  "bolts": [
    {
      "id": "count",
      "emitted": [
        {
          "stream_id": "__metrics",
          "value": 120
        },
        {
          "stream_id": "default",
          "value": 190748180
        },
        {
          "stream_id": "__ack_ack",
          "value": 190718100
        },
        {
          "stream_id": "__system",
          "value": 20
        }
      ],
      "transferred": [
        {
          "stream_id": "__metrics",
          "value": 120
        },
        {
          "stream_id": "default",
          "value": 0
        },
        {
          "stream_id": "__ack_ack",
          "value": 190718100
        },
        {
          "stream_id": "__system",
          "value": 0
        }
      ],
      "acked": [
        {
          "component_id": "split",
          "stream_id": "default",
          "value": 190733160
        }
      ],
      "failed": [

      ],
      "process_ms_avg": [
        {
          "component_id": "split",
          "stream_id": "default",
          "value": "0.004"
        }
      ],
      "executed": [
        {
          "component_id": "split",
          "stream_id": "default",
          "value": 190733140
        }
      ],
      "executed_ms_avg": [
        {
          "component_id": "split",
          "stream_id": "default",
          "value": "0.005"
        }
      ]
    },
    {
      "id": "split",
      "emitted": [
        {
          "stream_id": "__metrics",
          "value": 60
        },
        {
          "stream_id": "default",
          "value": 190754740
        },
        {
          "stream_id": "__ack_ack",
          "value": 17317580
        },
        {
          "stream_id": "__system",
          "value": 20
        }
      ],
      "transferred": [
        {
          "stream_id": "__metrics",
          "value": 60
        },
        {
          "stream_id": "default",
          "value": 190754740
        },
        {
          "stream_id": "__ack_ack",
          "value": 17317580
        },
        {
          "stream_id": "__system",
          "value": 0
        }
      ],
      "acked": [
        {
          "component_id": "spout",
          "stream_id": "default",
          "value": 17339180
        }
      ],
      "failed": [

      ],
      "process_ms_avg": [
        {
          "component_id": "spout",
          "stream_id": "default",
          "value": "0.051"
        }
      ],
      "executed": [
        {
          "component_id": "spout",
          "stream_id": "default",
          "value": 17339240
        }
      ],
      "executed_ms_avg": [
        {
          "component_id": "spout",
          "stream_id": "default",
          "value": "0.052"
        }
      ]
    }
  ]
}
```
##### 3.1.11 /api/v1/topology/\<id\>/component/\<component\>

使用如下 API 返回 Id 指定拓扑特定组件的详细度量指标以及Executor信息：
```
.../api/v1/topology/<id>/component/<component>
```
> <component> 组件Id

请求参数如下：

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |
|component |String (required)| Component Id |
|window    |String. Default value :all-time| window duration for metrics in seconds|
|sys       |String. Values 1 or 0. Default value 0| controls including sys stats part of the response|

返回字段如下：

|Field  |Value |Description|
|---	|---	|---
|user   | String | Topology owner|
|id   | String | Component id|
|encodedId   | String | URL encoded component id|
|name | String | Topology name|
|executors| Integer |Number of executor tasks in the component|
|tasks| Integer |Number of instances of component|
|requestedMemOnHeap| Double|Requested On-Heap Memory by User (MB)
|requestedMemOffHeap| Double|Requested Off-Heap Memory by User (MB)|
|requestedCpu| Double|Requested CPU by User (%)|
|schedulerDisplayResource| Boolean | Whether to display scheduler resource information|
|topologyId| String | Topology id|
|topologyStatus| String | Topology status|
|encodedTopologyId| String | URL encoded topology id|
|window    |String. Default value "All Time" | window duration for metrics in seconds|
|componentType | String | component type: SPOUT or BOLT|
|windowHint| String | window param value in "hh mm ss" format. Default value is "All Time"|
|debug| Boolean | If debug is enabled for the component|
|samplingPct| Double| Controls downsampling of events before they are sent to event log (percentage)|
|eventLogLink| String| URL viewer link to event log (debug mode)|
|profilingAndDebuggingCapable| Boolean |true if there is support for Profiling and Debugging Actions|
|profileActionEnabled| Boolean |true if worker profiling (Java Flight Recorder) is enabled|
|profilerActive| Array |Array of currently active Profiler Actions|
|componentErrors| Array of Errors | List of component errors|
|componentErrors.errorTime| Long | Timestamp when the exception occurred (Prior to 0.11.0, this field was named 'time'.)|
|componentErrors.errorHost| String | host name for the error|
|componentErrors.errorPort| String | port for the error|
|componentErrors.error| String |Shows the error happened in a component|
|componentErrors.errorLapsedSecs| Integer | Number of seconds elapsed since the error happened in a component |
|componentErrors.errorWorkerLogLink| String | Link to the worker log that reported the exception |
|spoutSummary| Array | (only for spouts) Array of component stats, one element per window.|
|spoutSummary.windowPretty| String |Duration passed in HH:MM:SS format|
|spoutSummary.window| String | window duration for metrics in seconds|
|spoutSummary.emitted| Long |Number of messages emitted in given window |
|spoutSummary.completeLatency| String (double value returned in String format) |Total latency for processing the message|
|spoutSummary.transferred| Long |Total number of messages transferred in given window|
|spoutSummary.acked| Long |Number of messages acked|
|spoutSummary.failed| Long |Number of messages failed|
|boltStats| Array | (only for bolts) Array of component stats, one element per window.|
|boltStats.windowPretty| String |Duration passed in HH:MM:SS format|
|boltStats.window| String| window duration for metrics in seconds|
|boltStats.transferred| Long |Total number of messages  transferred in given window|
|boltStats.processLatency| String (double value returned in String format)  |Average time of the bolt to ack a message after it was received|
|boltStats.acked| Long |Number of messages acked|
|boltStats.failed| Long |Number of messages failed|
|inputStats| Array | (only for bolts) Array of input stats|
|inputStats.component| String |Component id|
|inputStats.encodedComponentId| String |URL encoded component id|
|inputStats.executeLatency| Long | The average time a tuple spends in the execute method|
|inputStats.processLatency| Long | The average time it takes to ack a tuple after it is first received|
|inputStats.executed| Long |The number of incoming tuples processed|
|inputStats.acked| Long |Number of messages acked|
|inputStats.failed| Long |Number of messages failed|
|inputStats.stream| String |The name of the tuple stream given in the topology, or "default" if none specified|
|outputStats| Array | Array of output stats|
|outputStats.transferred| Long |Number of tuples emitted that sent to one ore more bolts|
|outputStats.emitted| Long |Number of tuples emitted|
|outputStats.stream| String |The name of the tuple stream given in the topology, or "default" if none specified|

Examples:

```no-highlight
1. http://<ui.host>:<ui.port>/api/v1/topology/WordCount3-1-1402960825/component/spout
2. http://<ui.host>:<ui.port>/api/v1/topology/WordCount3-1-1402960825/component/spout?sys=1
3. http://<ui.host>:<ui.port>/api/v1/topology/WordCount3-1-1402960825/component/spout?window=600
```

返回结果如下：
```json
{
  "name": "WordCount3",
  "id": "spout",
  "componentType": "spout",
  "windowHint": "10m 0s",
  "executors": 5,
  "componentErrors": [
    {
      "errorTime": 1406006074000,
      "errorHost": "10.11.1.70",
      "errorPort": 6701,
      "errorWorkerLogLink": "http://10.11.1.7:8000/log?file=worker-6701.log",
      "errorLapsedSecs": 16,
      "error": "java.lang.RuntimeException: java.lang.StringIndexOutOfBoundsException: Some Error\n\tat org.apache.storm.utils.DisruptorQueue.consumeBatchToCursor(DisruptorQueue.java:128)\n\tat org.apache.storm.utils.DisruptorQueue.consumeBatchWhenAvailable(DisruptorQueue.java:99)\n\tat org.apache.storm.disruptor$consume_batch_when_available.invoke(disruptor.clj:80)\n\tat backtype...more.."
    }
  ],
  "topologyId": "WordCount3-1-1402960825",
  "tasks": 5,
  "window": "600",
  "profilerActive": [
    {
      "host": "10.11.1.70",
      "port": "6701",
      "dumplink": "http:\/\/10.11.1.70:8000\/dumps\/ex-1-1452718803\/10.11.1.70%3A6701",
      "timestamp": "576328"
    }
  ],
  "profilingAndDebuggingCapable": true,
  "profileActionEnabled": true,
  "spoutSummary": [
    {
      "windowPretty": "10m 0s",
      "window": "600",
      "emitted": 28500,
      "transferred": 28460,
      "completeLatency": "0.000",
      "acked": 0,
      "failed": 0
    },
    {
      "windowPretty": "3h 0m 0s",
      "window": "10800",
      "emitted": 127640,
      "transferred": 127440,
      "completeLatency": "0.000",
      "acked": 0,
      "failed": 0
    },
    {
      "windowPretty": "1d 0h 0m 0s",
      "window": "86400",
      "emitted": 127640,
      "transferred": 127440,
      "completeLatency": "0.000",
      "acked": 0,
      "failed": 0
    },
    {
      "windowPretty": "All time",
      "window": ":all-time",
      "emitted": 127640,
      "transferred": 127440,
      "completeLatency": "0.000",
      "acked": 0,
      "failed": 0
    }
  ],
  "outputStats": [
    {
      "stream": "__metrics",
      "emitted": 40,
      "transferred": 0,
      "completeLatency": "0",
      "acked": 0,
      "failed": 0
    },
    {
      "stream": "default",
      "emitted": 28460,
      "transferred": 28460,
      "completeLatency": "0",
      "acked": 0,
      "failed": 0
    }
  ],
  "executorStats": [
    {
      "workerLogLink": "http://10.11.1.7:8000/log?file=worker-6701.log",
      "emitted": 5720,
      "port": 6701,
      "completeLatency": "0.000",
      "transferred": 5720,
      "host": "10.11.1.7",
      "acked": 0,
      "uptime": "43m 4s",
      "uptimeSeconds": 2584,
      "id": "[24-24]",
      "failed": 0
    },
    {
      "workerLogLink": "http://10.11.1.7:8000/log?file=worker-6703.log",
      "emitted": 5700,
      "port": 6703,
      "completeLatency": "0.000",
      "transferred": 5700,
      "host": "10.11.1.7",
      "acked": 0,
      "uptime": "42m 57s",
      "uptimeSeconds": 2577,
      "id": "[25-25]",
      "failed": 0
    },
    {
      "workerLogLink": "http://10.11.1.7:8000/log?file=worker-6702.log",
      "emitted": 5700,
      "port": 6702,
      "completeLatency": "0.000",
      "transferred": 5680,
      "host": "10.11.1.7",
      "acked": 0,
      "uptime": "42m 57s",
      "uptimeSeconds": 2577,
      "id": "[26-26]",
      "failed": 0
    },
    {
      "workerLogLink": "http://10.11.1.7:8000/log?file=worker-6701.log",
      "emitted": 5700,
      "port": 6701,
      "completeLatency": "0.000",
      "transferred": 5680,
      "host": "10.11.1.7",
      "acked": 0,
      "uptime": "43m 4s",
      "uptimeSeconds": 2584,
      "id": "[27-27]",
      "failed": 0
    },
    {
      "workerLogLink": "http://10.11.1.7:8000/log?file=worker-6703.log",
      "emitted": 5680,
      "port": 6703,
      "completeLatency": "0.000",
      "transferred": 5680,
      "host": "10.11.1.7",
      "acked": 0,
      "uptime": "42m 57s",
      "uptimeSeconds": 2577,
      "id": "[28-28]",
      "failed": 0
    }
  ]
}
```

#### 3.2 分析和调试GET操作

##### 3.2.1 /api/v1/topology/\<id\>/profiling/start/\<host-port\>/\<timeout\>

使用如下 API 请求在 Worker 上启动的分析器（带有超时时间）。 返回状态以及 worker 上分析器组件的链接：
```
.../api/v1/topology/<id>/profiling/start/<host-port>/<timeout>
```

请求字段如下：

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |
|host-port |String (required)| Worker Id |
|timeout |String (required)| Time out for profiler to stop in minutes |

返回字段如下:

|Field  |Value |Description|
|-----	|----- |-----------|
|id   | String | Worker id|
|status | String | Response Status |
|timeout | String | Requested timeout
|dumplink | String | Link to logviewer URL for worker profiler documents.|

Examples:

```no-highlight
1. http://ui-daemon-host-name:8080/api/v1/topology/wordcount-1-1446614150/profiling/start/10.11.1.7:6701/10
2. http://ui-daemon-host-name:8080/api/v1/topology/wordcount-1-1446614150/profiling/start/10.11.1.7:6701/5
3. http://ui-daemon-host-name:8080/api/v1/topology/wordcount-1-1446614150/profiling/start/10.11.1.7:6701/20
```
返回结果如下:
```json
{
   "status": "ok",
   "id": "10.11.1.7:6701",
   "timeout": "10",
   "dumplink": "http:\/\/10.11.1.7:8000\/dumps\/wordcount-1-1446614150\/10.11.1.7%3A6701"
}
```

##### 3.2.2 /api/v1/topology/\<id\>/profiling/dumpprofile/\<host-port\>

使用如下 API 请求在 Worker 上 dump 分析器记录。返回请求的状态和 Worker ID:
```
.../api/v1/topology/<id>/profiling/dumpprofile/<host-port>
```

请求字段如下：

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |
|host-port |String (required)| Worker Id |

返回字段如下:

|Field  |Value |Description|
|-----	|----- |-----------|
|id   | String | Worker id|
|status | String | Response Status |

Examples:
```no-highlight
1. http://ui-daemon-host-name:8080/api/v1/topology/wordcount-1-1446614150/profiling/dumpprofile/10.11.1.7:6701
```

返回结果如下:
```json
{
   "status": "ok",
   "id": "10.11.1.7:6701",
}
```
##### 3.2.3 /api/v1/topology/\<id\>/profiling/stop/\<host-port\>

使用如下 API 请求停止在 Worker 上的分析器。返回状态以及请求的 Worker Id:
```
/api/v1/topology/<id>/profiling/stop/<host-port>
```

请求字段如下:

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |
|host-port |String (required)| Worker Id |

返回字段如下:

|Field  |Value |Description|
|-----	|----- |-----------|
|id   | String | Worker id|
|status | String | Response Status |

Examples:

```no-highlight
1. http://ui-daemon-host-name:8080/api/v1/topology/wordcount-1-1446614150/profiling/stop/10.11.1.7:6701
```

返回结果:
```json
{
   "status": "ok",
   "id": "10.11.1.7:6701",
}
```

##### 3.2.4 /api/v1/topology/\<id\>/profiling/dumpjstack/\<host-port\>

使用如下 API 请求在 Worker 上 dump jstack。返回请求的状态和 Worker Id:
```
.../api/v1/topology/<id>/profiling/dumpjstack/<host-port>
```

请求字段如下：

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |
|host-port |String (required)| Worker Id |

返回字段如下:

|Field  |Value |Description|
|-----	|----- |-----------|
|id   | String | Worker id|
|status | String | Response Status |

Examples:
```no-highlight
1. http://ui-daemon-host-name:8080/api/v1/topology/wordcount-1-1446614150/profiling/dumpjstack/10.11.1.7:6701
```

返回结果如下:
```json
{
   "status": "ok",
   "id": "10.11.1.7:6701",
}
```
##### 3.2.5 /api/v1/topology/\<id\>/profiling/dumpheap/\<host-port\>

使用如下 API 请求在 Worker 上 dump heap。返回请求的状态和 Worker Id:
```
.../api/v1/topology/<id>/profiling/dumpheap/<host-port>
```

请求字段如下：

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |
|host-port |String (required)| Worker Id |

返回字段如下:

|Field  |Value |Description|
|-----	|----- |-----------|
|id   | String | Worker id|
|status | String | Response Status |

Examples:
```no-highlight
1. http://ui-daemon-host-name:8080/api/v1/topology/wordcount-1-1446614150/profiling/dumpheap/10.11.1.7:6701
```

返回结果如下:
```json
{
   "status": "ok",
   "id": "10.11.1.7:6701",
}
```

#### 3.3 POST 操作

##### 3.3.1 /api/v1/topology/\<id\>/activate

使用如下 API 激活指定拓扑：
```
.../api/v1/topology/<id>/activate
```

请求参数如下：

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |

返回结果如下：
```json
{
  "topologyOperation": "activate",
  "topologyId": "wordcount-1-1420308665",
  "status": "success"
}
```

##### 3.3.2 /api/v1/topology/\<id\>/deactivate

使用如下 API 停用指定拓扑：
```
.../api/v1/topology/<id>/deactivate
```

请求参数如下：

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |

返回结果如下：
```json
{
  "topologyOperation": "deactivate",
  "topologyId": "wordcount-1-1420308665",
  "status": "success"
}
```
##### 3.3.3 /api/v1/topology/\<id\>/rebalance/\<wait-time\>

使用如下 API 重平衡指定拓扑：
```
.../api/v1/topology/<id>/rebalance/<wait-time>
```

请求参数如下：

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |
|wait-time |String (required)| Wait time before rebalance happens |
|rebalanceOptions| Json (optional) | topology rebalance options |

平衡可选参数如下：
```json
{
  "rebalanceOptions": {
    "numWorkers": 2,
    "executors": {
      "spout": 4,
      "count": 10
    }
  },
  "callback": "foo"
}
```
Example：
```
curl  -i -b ~/cookiejar.txt -c ~/cookiejar.txt -X POST  
-H "Content-Type: application/json"
-d  '{"rebalanceOptions": {"numWorkers": 2, "executors": { "spout" : "5", "split": 7, "count": 5 }}, "callback":"foo"}'
http://localhost:8080/api/v1/topology/wordcount-1-1420308665/rebalance/0
```
返回结果如下：
```json
{
  "topologyOperation": "rebalance",
  "topologyId": "wordcount-1-1420308665",
  "status": "success"
}
```

##### 3.3.4 /api/v1/topology/\<id\>/kill/\<wait-time\>

使用如下 API 杀死指定拓扑：
```
.../api/v1/topology/<id>/kill/<wait-time>
```
请求参数如下：

|Parameter |Value   |Description  |
|----------|--------|-------------|
|id   	   |String (required)| Topology Id  |
|wait-time |String (required)| Wait time before rebalance happens |

返回结果如下：
```json
{
  "topologyOperation": "kill",
  "topologyId": "wordcount-1-1420308665",
  "status": "succe"
}
```

英译对照:
- host: 主机

> Storm版本: 2.0.0

欢迎关注我的公众号和博客：

![](https://github.com/sjf0115/PubLearnNotes/blob/master/image/Other/smartsi.jpg?raw=true)

原文:[Storm UI REST API](https://storm.apache.org/releases/2.0.0/STORM-UI-REST-API.html)