<%@ page contentType="text/html; charset=utf-8" %>
<%@ taglib prefix="a" uri="/WEB-INF/app.tld" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="res" uri="http://www.unidal.org/webres" %>
<%@ taglib prefix="w" uri="http://www.unidal.org/web/core" %>
<jsp:useBean id="ctx" type="com.dianping.cat.system.page.config.Context" scope="request"/>
<jsp:useBean id="payload" type="com.dianping.cat.system.page.config.Payload" scope="request"/>
<jsp:useBean id="model" type="com.dianping.cat.system.page.config.Model" scope="request"/>

<a:config>
    <res:useJs value="${res.js.local['jquery.validate.min.js']}" target="head-js"/>
    <res:useJs value="${res.js.local['editor.js']}" target="head-js"/>
    <script src='${model.webapp}/assets/js/editor/ace.js'></script>

    <style>
        .cat-alarm-tip {
            padding: 1em;
        }

        .cat-alarm-tip-container {
            padding: 0.5em;
            border: 1px solid #ffeeba;
            background-color: #fff3cd;
            color: #856404;
        }

        .cat-alarm-tip-container h4 {
            font-size: 1.5em;
            padding: 0;
            margin: 0 0 0.3em;
        }

        .cat-alarm-tip-container p {
            margin-bottom: 0.3em;
        }

        .cat-alarm-tip-container button {
            margin-right: 0.5em;
            padding: 0.2em 0.5em;
        }

        .cat-alarm-tip-container a.question {
            margin-right: 0.5em;
            cursor: not-allowed;
            color: #CCC;
        }
    </style>

    <div class="cat-alarm-tip">
        <div class="cat-alarm-tip-container">
            <h4>配置说明：</h4>
            <p><strong>基本配置</strong></p>
            <p>* local-mode：仅用于本地开发。设置为 true 后使用本地存储，并将报表查询线程固定为 5；生产环境应保持 false。</p>
            <p>* job-machine：执行报表汇总、统计和数据清理等后台任务。集群中通常只为一个或少量节点设置为 true。</p>
            <p>* send-machine：发送告警通知。集群中通常只为承担通知发送职责的节点设置为 true。</p>
            <p>* alarm-machine：执行告警规则计算。集群中应避免多个节点重复计算同一批告警。</p>
            <p>* consumer-machine：接收并实时分析客户端消息。设置为 false 后该节点不监听 TCP 2280 端口，可作为纯控制台或任务节点；修改后需要重启。</p>
            <p>* hdfs-enabled：是否启用 HDFS 存储。设置为 false 时使用 local-base-dir 指定的本地目录。</p>
            <p>* remote-servers：CAT 控制台集群地址，格式为 host:HTTP端口，多个地址使用英文逗号分隔，例如 10.0.0.1:8080,10.0.0.2:8080。</p>
            <p>* netty-boss-threads：TCP 连接接收线程数，通常保持 1；控制节点关闭 consumer-machine 后不会创建该线程。</p>
            <p>* netty-worker-threads：TCP 网络读写和消息解码线程数。auto 会综合 cgroup 和 JVM CPU 信息，自动值最多为 4；Kubernetes 中无法读取 cgroup 时回退为 1。需要超过 4 个线程时应显式填写整数，修改后需要重启。</p>
            <p>* report-query-threads：报表查询、读取和模型合并的并发线程数，默认 8；调大后会增加数据库、磁盘和 CPU 压力，修改后需要重启。</p>
            <p>* max-message-size：单条 TCP 消息的字节上限，默认 4194304（4 MiB），最大允许 64 MiB；超限消息会被拒绝，修改后需要重启。</p>
            <p>* graceful-shutdown-timeout-seconds：收到 SIGTERM 后停止接收消息、排空分析队列并完成最终落盘的超时时间，默认 25 秒；应小于 Pod 的 terminationGracePeriodSeconds。</p>
            <p>* daily-checkpoint-enabled：是否启用每日在线快照，默认 true。快照会刷新报表和原始消息文件，但不会停止消息接收或关闭当前小时存储。</p>
            <p>* daily-checkpoint-hour：每日在线快照的执行小时，取值 0 至 23，默认 4。</p>
            <p>* daily-checkpoint-minute：每日在线快照的执行分钟，取值 0 至 59，默认 0。</p>
            <p>* message-processor-thread：消息持久化线程数，默认 8。每个线程拥有独立队列；调大后会增加内存、磁盘和线程开销，修改后需要重启。</p>
            <p>* message-processor-queue-size：每个持久化线程的队列容量，默认 5000 条。总容量约为线程数乘以该值；队列满时新消息会被丢弃。</p>

            <p><strong>分析器配置</strong></p>
            <p>* realtime-analyzer-queue-capacity-per-thread：每个实时分析器工作线程的默认队列容量，默认 10000 条。每个分析器实例都有独立队列，调大后总内存占用会成倍增加；下一个整点生效。</p>
            <p>* top-analyzer-enable：监控大盘分析开关，按分钟汇总应用错误和错误机器排行。</p>
            <p>* business-analyzer-enable：业务指标分析开关，聚合客户端上报的 Metric 指标。</p>
            <p>* matrix-analyzer-enable：性能报告分析开关，统计 URL、Service、RPC 等调用的成功率和耗时分布。</p>
            <p>* storage-analyzer-enable：存储调用分析开关，统计数据库、缓存等调用的次数、耗时和错误。</p>
            <p>* dependency-analyzer-enable：服务依赖分析开关，分析应用与数据库、缓存、服务等下游资源的依赖关系。</p>

            <p><strong>存储配置</strong></p>
            <p>* local-base-dir：本地消息和报表文件的存储根目录；容器部署时应挂载持久卷。</p>
            <p>* max-hdfs-storage-time：HDFS 数据保留天数。</p>
            <p>* local-report-storage-time：本地报表保留天数。</p>
            <p>* local-logivew-storage-time：本地原始消息日志保留天数。</p>
            <p>* har-mode：是否将历史 HDFS 文件归档为 HAR，以减少小文件数量。</p>
            <p>* upload-thread：本地文件上传到 HDFS 的并发线程数；调大后会增加网络、磁盘和 HDFS 压力。</p>
            <p>* hdfs：HDFS 写入配置。max-size 为单文件最大尺寸，server-uri 为 HDFS 地址，base-dir 为写入目录。</p>
            <p>* harfs：HAR 归档读取配置。max-size 为单文件最大尺寸，server-uri 为 HAR 地址，base-dir 为归档目录。</p>
            <p>* hadoop.security.authentication：是否启用 Hadoop 安全认证。</p>
            <p>* dfs.namenode.kerberos.principal：NameNode 的 Kerberos Principal。</p>
            <p>* dfs.cat.kerberos.principal：CAT 服务使用的 Kerberos Principal。</p>
            <p>* dfs.cat.keytab.file：CAT 服务的 Kerberos keytab 文件路径。</p>
            <p>* java.security.krb5.realm：Kerberos Realm。</p>
            <p>* java.security.krb5.kdc：Kerberos KDC 地址。</p>

            <p><strong>慢调用阈值</strong></p>
            <p>* default-url-threshold：URL/Transaction 默认慢调用阈值，单位为毫秒。</p>
            <p>* default-sql-threshold：SQL 默认慢调用阈值，单位为毫秒。</p>
            <p>* default-service-threshold：Service/RPC 默认慢调用阈值，单位为毫秒。</p>
            <p>* domain：为指定应用覆盖 url-threshold、sql-threshold 和 service-threshold；未填写的值继续使用默认阈值。</p>

            <p><strong>集群节点覆盖</strong></p>
            <p>* default 节点保存全局默认配置；其他 server 节点只填写需要覆盖的 property，例如为指定节点开启 job-machine、send-machine 或 alarm-machine。</p>
        </div>
    </div>

    <form name="serverConfigUpdate" id="form" method="post"
          action="${model.pageUri}?op=serverConfigUpdate">
        <table class="table table-striped table-condensed  table-hover">
            <tr>
                <td>
                    <input id="content" name="content" value="" type="hidden"/>
                    <div id="editor" class="editor">${model.content}</div>
                </td>
            </tr>
            <tr>
                <td style="text-align:center"><input class='btn btn-primary' id="serverConfigUpdate"
                                                     type="submit" name="submit" value="提交"/></td>
            </tr>
        </table>
    </form>
    <h4 class="text-center text-danger" id="state">&nbsp;</h4>
</a:config>
<script type="text/javascript">
    $(document).ready(function () {
        $('#system-config').addClass('active open');
        $('#serverConfigUpdate').addClass('active');
        var state = '${model.opState}';
        if (state == 'Success') {
            $('#state').html('操作成功');
        } else {
            $('#state').html('操作失败');
        }
        setInterval(function () {
            $('#state').html('&nbsp;');
        }, 3000);
    });
</script>
