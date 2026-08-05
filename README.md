<img src="https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/readme/icon.png" align="right" />

[license-apache2.0]:https://www.apache.org/licenses/LICENSE-2.0.html

[github-action]:https://github.com/shiyindaxiaojie/cat/actions

[sonarcloud-dashboard]:https://sonarcloud.io/dashboard?id=shiyindaxiaojie_cat

# CAT 实时监控平台

> 面向企业级生产环境的增强发行版，聚焦稳定运行、容器化部署、链路追踪与告警闭环。

简体中文 | [English](README-en.md)

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/readme/language-java-blue.svg) [![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/readme/license-apache2.0-red.svg)][license-apache2.0] [![](https://github.com/shiyindaxiaojie/cat/actions/workflows/release.yml/badge.svg?branch=release)][github-action] [![](https://img.shields.io/docker/pulls/shiyindaxiaojie/cat-home?label=Docker%20Pulls)](https://hub.docker.com/repository/docker/shiyindaxiaojie/cat-home)

CAT 是美团点评开源的实时应用监控平台。笔者在保留原有 `Transaction`、`Event`、`Problem`、`Business` 等核心能力和使用习惯的基础上，面向真实生产场景持续增强链路排障、告警协同、监控大盘与容器化部署体验。

- **链路排障更高效**：根据日志中的 Trace ID 检索完整消息树，串联 HTTP、RPC、SQL、缓存与业务日志。
- **告警渠道开箱即用**：支持邮件、钉钉、企业微信和飞书机器人，无需为消息转发额外部署服务。
- **监控全景更直观**：增强应用、数据库、缓存和服务大盘，并提供相应告警能力。
- **故障处理有闭环**：告警可自动录入 Jira Software，减少人工转派和跟进成本。

本项目已在生产环境持续运行。首次接入或排查常见问题时，可查阅[实践笔记](https://mengxiangge.netlify.app/article/github/cat-add-tracing-alerting)。

**快速导航**：[功能预览](#功能预览) · [构建项目](#构建项目) · [本地启动](#本地启动) · [部署方式](#部署方式) · [客户端接入](#客户端接入) · [更新日志](CHANGELOG.md)

## 功能预览

### 更清晰的监控界面

改造前：

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/dashboard-old.png)

改造后：

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/dashboard.png)

### 链路跟踪

通过日志中的 Trace ID 还原完整请求路径，集中查看 HTTP 请求耗时、RPC 调用、Log4j2 业务日志、SQL 与缓存执行情况。

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/tracing.png)

### 多渠道告警

支持邮件、钉钉、企业微信和飞书机器人推送，帮助团队快速接入现有协作流程。

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/dingtalk.png)

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/mail.png)

### 生产视角大盘

从应用、数据库、缓存和 RPC 服务等视角集中展示系统状态，更容易发现异常节点和影响范围。

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/app-dashboard.png)

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/database-dashboard.png)

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/cache-dashboard.png)

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/rpc-dashboard.png)

### 更多监控视图

#### Transaction

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/transaction.png)

#### Event

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/event.png)

#### Business

Business 适合展示比 Transaction 和 Event 更宏观的业务指标，需要应用侧主动埋点。

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/business.png)

推荐使用  [`eden-cat-spring-boot-starter`](https://github.com/shiyindaxiaojie/eden-architect/tree/main/eden-components/eden-spring-integration/src/main/java/org/ylzl/eden/spring/integration/cat) 提供的 `@CatMetric` 注解实现埋点，支持 SpEL 表达式，代码示例如下：

```java
@CatMetric(name = "'客户[' + #cust.custId + ']资产查询调用次数'", count = 1)
public Response listAsset(Cust cust) {
    //
}
```

#### Matrix

汇总接口的调用量、成功率和耗时分布。

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/matrix.png)

#### Cross

检索指定 RPC 接口的调用方、调用量与执行情况。

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/rpc.png)

#### Heart Beat

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/heartbeat.png)

#### Dependency

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/dependency.png)

#### Browser

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/browser.png)

#### Mobile

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/mobile.png)

#### State

查看当前 CAT 服务端与应用节点的运行状态。

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/state.png)

## 构建项目

本项目默认使用 Maven 来构建，最快的使用方式是 `git clone` 到本地。在项目的根目录执行 `mvn install -T 4C` 完成本项目的构建。

## 本地启动

### IDEA 启动

1. 在用户目录创建文件夹 `~/.cat/appdatas/cat`，拷贝本项目的 `docs/config` 到该目录下
2. 修改 `docs/config/datasources.xml` 的数据库连接信息
3. 在上述目标数据源执行 `docs/scripts/cat-init-3.4.0.sql` 初始化
4. 检查 `cat-home` 模块已正确设置了 Facet
   ![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/idea-cat-home-facet.png)
5. 使用 IDEA 配置 Tomcat 服务器，请注意，多网卡情况下可能会出现 `CAT服务端异常:[127.0.0.1]`，请设置 JVM 启动参数 `host.ip` 指定 IP。
   ![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/idea-tomcat-settings.png)
6. 指定访问入口 Context 为 `/cat`
   ![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/idea-tomcat-deployment.png)
7. 运行 Tomcat 服务器，启动成功后，自动打开 `http://localhost:8080/cat`

### Docker 启动

本项目已发布到 [Docker Hub](https://hub.docker.com/repository/docker/shiyindaxiaojie/cat-home)，配置数据库连接后即可启动：

```bash
docker run \
  -e MYSQL_URL="127.0.0.1" \
  -e MYSQL_PORT="3306" \
  -e MYSQL_SCHEMA="cat" \
  -e MYSQL_USERNAME="" \
  -e MYSQL_PASSWORD="" \
  -p 8080:8080 \
  --name cat-home \
  -d shiyindaxiaojie/cat-home
```

## 部署方式

> **停机保护：**当前 Docker/Helm 部署已集成优雅停机处理。使用传统 Tomcat 或自定义启动方式时，建议在停止 CAT 前调用 `curl http://localhost:8080/cat/r/home?op=checkpoint`，先将内存中的数据持久化到磁盘。从 3.4.3 版本开始，系统内部会定时持久化数据，不再需要调用此接口。

### Tomcat 部署

拷贝本项目的 `docs/config` 到用户目录 `~/.cat/appdatas/cat` 中，按需调整数据库配置。执行 `mvn clean package` 打包成一个 cat-home.war，部署在目标 Tomcat 的 `webapps` 目录下，启动 Tomcat 即可。

### Docker 部署

在项目根目录执行 `docker build -f docker/Dockerfile -t cat:{tag} .` 构建镜像。

### Helm 部署

进入 `helm` 目录，执行 `helm install -n cat --create-namespace cat .` 安装，在 Kubernetes 环境中自动创建 CAT 所需的资源。

## 客户端接入

为了减少客户端集成的工作，您可以使用 [eden-architect](https://github.com/shiyindaxiaojie/eden-architect) 框架，只需要两步就可以完成 CAT 的集成。

1. 引入 CAT 依赖
````xml
<dependency>
    <groupId>io.github.shiyindaxiaojie</groupId>
    <artifactId>eden-cat-spring-boot-starter</artifactId>
</dependency>
````
2. 开启 CAT 配置
````yaml
cat:
  enabled: false # 默认关闭，请按需开启
  trace-mode: true # 开启访问观测
  support-out-trace-id: false # 允许异构子系统间透传链路ID
  home: /tmp
  servers: localhost # CAT 地址
  tcp-port: 2280
  http-port: 8080

# 如果您使用 Dubbo 组件，请增加对应的过滤器，确保 CAT 埋点正常工作
dubbo:
  provider:
    filter: cat-tracing
  consumer:
    filter: cat-tracing,cat-consumer
````

另外，笔者提供了两种不同应用架构的示例，里面有集成 CAT 的示例。
* 面向领域模型的 **COLA 架构**，代码实例可以查看 [eden-demo-cola](https://github.com/shiyindaxiaojie/eden-demo-cola)
* 面向数据模型的 **分层架构**，代码实例请查看 [eden-demo-layer](https://github.com/shiyindaxiaojie/eden-demo-layer)

## 版本规范

项目的版本号格式为 `x.y.z` 的形式，其中 x 的数值类型为数字，从 0 开始取值，且不限于 0~9 这个范围。项目处于孵化器阶段时，第一位版本号固定使用 0，即版本号为 `0.x.x` 的格式。

* 孵化版本：0.0.1-SNAPSHOT
* 开发版本：1.0.0-SNAPSHOT
* 发布版本：1.0.0

版本迭代规则：

* 1.0.0 <> 1.0.1：兼容
* 1.0.0 <> 1.1.0：基本兼容
* 1.0.0 <> 2.0.0：不兼容

## 变更日志

请查阅 [CHANGELOG.md](https://github.com/shiyindaxiaojie/cat/blob/main/CHANGELOG.md)
