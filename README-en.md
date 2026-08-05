<img src="https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/readme/icon.png" align="right" />

[license-apache2.0]:https://www.apache.org/licenses/LICENSE-2.0.html

[github-action]:https://github.com/shiyindaxiaojie/cat/actions

[sonarcloud-dashboard]:https://sonarcloud.io/dashboard?id=shiyindaxiaojie_cat

# CAT Real-Time Monitoring Platform

> An enhanced distribution for enterprise production environments, focused on operational stability, containerized deployment, request tracing, and closed-loop alert management.

English | [简体中文](README.md)

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/readme/language-java-blue.svg) [![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/readme/license-apache2.0-red.svg)][license-apache2.0] [![](https://github.com/shiyindaxiaojie/cat/actions/workflows/release.yml/badge.svg?branch=release)][github-action] [![](https://img.shields.io/docker/pulls/shiyindaxiaojie/cat-home?label=Docker%20Pulls)](https://hub.docker.com/repository/docker/shiyindaxiaojie/cat-home)

CAT is a real-time application monitoring platform open-sourced by Meituan-Dianping. While preserving CAT's familiar core capabilities, including `Transaction`, `Event`, `Problem`, and `Business`, this project adds production-oriented improvements for request troubleshooting, alert collaboration, monitoring dashboards, and containerized deployment.

- **Faster request troubleshooting**: Find complete message trees by Trace ID and correlate HTTP, RPC, SQL, cache operations, and application logs.
- **Ready-to-use alert channels**: Send alerts through email, DingTalk, WeCom, and Feishu bots without deploying an additional message relay service.
- **Clearer operational visibility**: Use enhanced application, database, cache, and service dashboards with corresponding alert capabilities.
- **Closed-loop incident handling**: Automatically create Jira Software issues from alerts to reduce manual assignment and follow-up work.

This project has been running continuously in production environments. For onboarding guidance and common troubleshooting tips, see the [practical guide](https://mengxiangge.netlify.app/article/github/cat-add-tracing-alerting).

**Quick navigation**: [Feature Preview](#feature-preview) · [Build](#build) · [Local Startup](#local-startup) · [Deployment](#deployment) · [Client Integration](#client-integration) · [Changelog](CHANGELOG.md)

## Feature Preview

### A Clearer Monitoring Interface

Before:

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/dashboard-old.png)

After:

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/dashboard.png)

### Request Tracing

Reconstruct an end-to-end request path from a Trace ID and inspect HTTP latency, RPC calls, Log4j2 application logs, SQL execution, and cache operations in one place.

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/tracing.png)

### Multi-Channel Alerts

Deliver alerts through email, DingTalk, WeCom, and Feishu bots so teams can integrate CAT with their existing collaboration workflows.

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/dingtalk.png)

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/mail.png)

### Production-Oriented Dashboards

View system health from the perspectives of applications, databases, caches, and RPC services to identify affected nodes and blast radius more quickly.

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/app-dashboard.png)

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/database-dashboard.png)

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/cache-dashboard.png)

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/rpc-dashboard.png)

### More Monitoring Views

#### Transaction

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/transaction.png)

#### Event

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/event.png)

#### Business

Business metrics provide a higher-level view than Transaction and Event metrics and require explicit application-side instrumentation.

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/business.png)

We recommend the `@CatMetric` annotation provided by [`eden-cat-spring-boot-starter`](https://github.com/shiyindaxiaojie/eden-architect/tree/main/eden-components/eden-spring-integration/src/main/java/org/ylzl/eden/spring/integration/cat). It supports SpEL expressions, as shown below:

```java
@CatMetric(name = "'客户[' + #cust.custId + ']资产查询调用次数'", count = 1)
public Response listAsset(Cust cust) {
    //
}
```

#### Matrix

Summarize request volume, success rate, and latency distribution across service endpoints.

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/matrix.png)

#### Cross

Inspect callers, request volume, and execution details for a specific RPC interface.

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

Inspect the runtime status of CAT servers and monitored application nodes.

![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/state.png)

## Build

This project uses Maven. Clone the repository and run `mvn install -T 4C` from the project root to build all modules.

## Local Startup

### Start from IntelliJ IDEA

1. Create `~/.cat/appdatas/cat` under your user directory and copy `docs/config` into it.
2. Update the database connection in `docs/config/datasources.xml`.
3. Run `docs/scripts/cat-init-3.4.0.sql` against the target database.
4. Verify that the Facet for the `cat-home` module is configured correctly.
   ![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/idea-cat-home-facet.png)
5. Configure a Tomcat server in IDEA. On hosts with multiple network interfaces, `CAT服务端异常:[127.0.0.1]` may appear; set the JVM option `host.ip` to the desired address.
   ![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/idea-tomcat-settings.png)
6. Set the application context path to `/cat`.
   ![](https://cdn.jsdelivr.net/gh/shiyindaxiaojie/images/cat/idea-tomcat-deployment.png)
7. Start Tomcat. After a successful startup, open `http://localhost:8080/cat`.

### Start with Docker

The image is available on [Docker Hub](https://hub.docker.com/repository/docker/shiyindaxiaojie/cat-home). Configure the database connection and start CAT with:

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

## Deployment

> **Shutdown protection:** The current Docker and Helm deployments include graceful shutdown handling. For traditional Tomcat or custom startup methods, call `curl http://localhost:8080/cat/r/home?op=checkpoint` before stopping CAT to persist in-memory data. Starting with version 3.4.3, CAT also persists data periodically, so this endpoint no longer needs to be called manually.

### Tomcat

Copy `docs/config` to `~/.cat/appdatas/cat` and adjust the database configuration as needed. Run `mvn clean package` to build `cat-home.war`, deploy it to the target Tomcat `webapps` directory, and start Tomcat.

### Docker

Run `docker build -f docker/Dockerfile -t cat:{tag} .` from the project root to build an image.

### Helm

Enter the `helm` directory and run `helm install -n cat --create-namespace cat .`. Helm will create the resources required by CAT in Kubernetes.

## Client Integration

To reduce client integration work, use the [eden-architect](https://github.com/shiyindaxiaojie/eden-architect) framework to integrate CAT in two steps.

1. Add the CAT dependency:

````xml
<dependency>
    <groupId>io.github.shiyindaxiaojie</groupId>
    <artifactId>eden-cat-spring-boot-starter</artifactId>
</dependency>
````

2. Enable CAT:

````yaml
cat:
  enabled: false # Disabled by default; enable it when needed
  trace-mode: true # Enable request tracing
  support-out-trace-id: false # Propagate Trace IDs across heterogeneous subsystems
  home: /tmp
  servers: localhost # CAT server address
  tcp-port: 2280
  http-port: 8080

# Add the filters below when using Dubbo so that CAT instrumentation works correctly
dubbo:
  provider:
    filter: cat-tracing
  consumer:
    filter: cat-tracing,cat-consumer
````

Two example applications demonstrate CAT integration with different architecture styles:

- **COLA/domain-oriented architecture**: [eden-demo-cola](https://github.com/shiyindaxiaojie/eden-demo-cola)
- **Layered/data-oriented architecture**: [eden-demo-layer](https://github.com/shiyindaxiaojie/eden-demo-layer)

## Versioning

Versions follow the `x.y.z` format. Each component is numeric, starts at 0, and is not limited to a single digit. During incubation, the major version remains 0, resulting in versions such as `0.x.x`.

- Incubation version: `0.0.1-SNAPSHOT`
- Development version: `1.0.0-SNAPSHOT`
- Release version: `1.0.0`

Compatibility rules:

- `1.0.0` <> `1.0.1`: compatible
- `1.0.0` <> `1.1.0`: mostly compatible
- `1.0.0` <> `2.0.0`: incompatible

## Changelog

See [CHANGELOG.md](https://github.com/shiyindaxiaojie/cat/blob/main/CHANGELOG.md).
