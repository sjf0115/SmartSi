---
layout: post
author: sjf0115
title: Hive 分桶 Bucket
date: 2016-11-20 20:16:01
tags:
  - Hive

categories: Hive
permalink: hive-base-how-to-use-bucket
---

### 1. 概述

通常 Hive 中的分区功能提供了一种将 Hive 表数据分隔成多个文件/目录的方法。当只有有限个分区，分区大小差不多大情况下，分区会产生不错的效果。但在有些情况下并不能如我们所愿，比如，当我们根据国家对表进行分区时，一些较大的国家会有较大的分区（例如：4-5个国家就占总数据的70-80％），然而一些小国家分区会比较小（剩余的所有国家可能只占全部数据的20-30％）。

Hive 中的分区提供了一个隔离数据和优化查询的便利方式，不过并非所有的数据都可形成合理的分区，例如，上面的情形。在这种情形下分区并不理想，为了解决分区的这个问题，Hive 引入分桶的概念。Hive 中的分桶是另一种将数据切分为更小片段的方式。分区就是一个目录，在分桶中，每个桶都是保存实际数据的一个文件(一个桶对应一个文件)。

将表（或者分区）组织成分桶有两个主要的原因：
- 第一是获得更高的查询效率。桶为表加上了额外的结构。Hive 在处理有些查询时能够利用这个结构。具体而言，Join 两个在相同列上划分分桶的表，可以获得更高的效率。
- 第二是使抽样更高效。在处理大规模数据集时，在开发和修改查询的阶段，如果能在数据集的一小部分数据上运行查询，会带来很多方便。

分桶具有如下特征：
- 分桶基于对分桶列值进行哈希并将结果除以桶的个数取余数。哈希函数取决于分桶列的类型。
- 具有相同分桶列的记录存储在同一个分桶中。
- 我们使用 `CLUSTERED BY` 子句划分分桶。
- 从物理上讲，每个桶只是表目录中的一个文件，桶编号从下标1开始。
- 分桶可以与分区一起使用，也可以不需要分区。
- 分桶表数据文件分布比较均衡。

### 2. 用法

我们先来看看一个表如何被划分成桶。我们可以在 `CREATE TABLE` 语句中使用 `CLUSTERED BY` 子句和可选的 `SORTED BY` 子句来制定划分桶所用的列和要划分的桶的个数：
```sql
CREATE TABLE bucketed_user(
  name string,
  state string,
  city  string
)
PARTITIONED BY (country string)
CLUSTERED BY (state) INTO 32 BUCKETS;
```
这里我们使用用户所在的州（state）来确定如何划分分桶（Hive 对值进行哈希并将结果除以桶的个数取余数）。这样，任何一桶里都会有一个随机的用户集合。

> 上表使用用户所在的国家（country）来确定如何划分分区。

桶中的数据可以根据一个或者多个列另外进行排序。如下所示根据 city 进行排序：
```sql
CREATE TABLE bucketed_users(
  name string,
  state string,
  city  string
)
PARTITIONED BY (country string)
CLUSTERED BY (state) SORTED BY (city) INTO 4 BUCKETS;
```

假设我们有一个没有划分桶的用户表：
```
hive> SELECT name, country, state, city FROM users;
OK
Rebbe   AU      TA      Leith
Stevie  AU      QL      Proston
Mariko  AU      WA      Hamel
Gerardo AU      NS      Talmalmo
Mayra   AU      NS      Lane Cove
Idella  AU      WA      Cartmeticup
Sherill AU      WA      Nyamup
Ena     AU      NS      Bendick Murrell
Vince   AU      QL      Purrawunda
...
```
要向分桶后的表中填充数据，需要将 `hive.enforce.bucketing` 属性设置为 `true`。这样 Hive 就知道用表定义中声明的数量创建桶（自动使用正确的 Reducer 个数和 Group By 列，否则你需要手动设置 Reducer 个数跟桶的个数一致），然后使用 `INSERT` 命令即可：
```sql
SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.enforce.bucketing = true;

INSERT OVERWRITE TABLE bucketed_users
PARTITION (country)
SELECT name, state, city, country
FROM users;
```

> 属性 `hive.enforce.bucketing` 类似于分区中的 `hive.exec.dynamic.partition` 属性。通过设置此属性，我们才能将数据加载到 Hive 表时启用动态分桶。

> 在 Hive 2.x 之前，属性 `hive.enforce.bucketing` 默认值为 `false`，使用分桶时需要手动设置为 `true`。在 Hive 2.x 之后，该属性被删除，表示永远为 `true`。

物理上，每个桶就是表（或者分区）目录里的一个文件。它的文件名称并不重要，但是桶 `n` 是按照字典序排列的第 `n` 个文件。事实上，桶对应于 MapReduce 的输出文件分区：一个作业产生的桶（输出文件）和 Reduce 任务个数相同。我们通过查看刚才创建创建的分桶表的布局来了解这一点。运行如下命令：
```
[sjf0115@ying ~]$  hadoop fs -ls /user/hive/warehouse/hive.db/bucketed_users/
Found 5 items
drwxr-xr-x   - sjf0115 supergroup  0 2018-08-03 13:12 /user/hive/warehouse/hive.db/bucketed_users/country=AU
drwxr-xr-x   - sjf0115 supergroup  0 2018-08-03 13:12 /user/hive/warehouse/hive.db/bucketed_users/country=CA
drwxr-xr-x   - sjf0115 supergroup  0 2018-08-03 13:12 /user/hive/warehouse/hive.db/bucketed_users/country=UK
drwxr-xr-x   - sjf0115 supergroup  0 2018-08-03 13:12 /user/hive/warehouse/hive.db/bucketed_users/country=US
[sjf0115@ying ~]$
[sjf0115@ying ~]$  hadoop fs -ls /user/hive/warehouse/hive.db/bucketed_users/country=AU/
Found 4 items
-rwxr-xr-x 3 sjf0115 supergroup 0 2018-08-03 13:12 /user/hive/warehouse/hive.db/bucketed_users/country=AU/000000_0
-rwxr-xr-x 3 sjf0115 supergroup 3280 2018-08-03 13:12 /user/hive/warehouse/hive.db/bucketed_users/country=AU/000001_0
-rwxr-xr-x 3 sjf0115 supergroup 2903 2018-08-03 13:12 /user/hive/warehouse/hive.db/bucketed_users/country=AU/000002_0
-rwxr-xr-x 3 sjf0115 supergroup 4156 2018-08-03 13:12 /user/hive/warehouse/hive.db/bucketed_users/country=AU/000003_0
```
我们看到每个分区下都有4个新建的文件。文件名如下：
```
000000_0
000001_0
000002_0
000003_0
```

### 3. 注意事项

下面是在 Hive 中使用分桶时应该遵循的一些最佳实践：
- 选择唯一值个数比较多的桶键，这样会降低出现数据倾斜的概率。
- 采用质数作为桶的编号。
- 分桶对于多表 Join 非常有用。需要注意的是，Join 表的桶个数必须相同，或者一个表的桶个数是另一个表桶个数的因子。
- 表建好之后，桶的个数就不能改变了。
- 仔细考虑桶的个数。一个 CPU 核只会对一个桶进行写入操作，因此对于一个大型集群，如果桶的个数很小，则集群的利用严重不足。
- 仔细考虑选择进行分桶的列，因为散列函数会引发数据倾斜。

参考：　
- http://hadooptutorial.info/bucketing-in-hive/
- https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL+BucketedTables
- Hive 实战
