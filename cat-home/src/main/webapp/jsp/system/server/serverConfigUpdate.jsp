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
            <p><strong>server.properties（顺序与默认配置一致）</strong></p>
            <p>* local-mode：本地开发模式；启用后不访问 HDFS，并把报表查询线程固定为 5，不建议生产环境开启。默认 false。</p>
            <p>* job-machine：是否执行报表汇总、清理等定时任务；集群中通常只让少量节点承担。默认 false。</p>
            <p>* send-machine：是否承担通知发送任务。默认 false。</p>
            <p>* alarm-machine：是否执行告警计算任务；集群中应避免所有节点重复计算告警。默认 false。</p>
            <p>* hdfs-enabled：是否启用 HDFS 存储；设置为 false 时使用本地目录。默认 false。</p>
            <p>* remote-servers：CAT 控制台节点列表，格式为 host:HTTP端口，多个节点用英文逗号分隔；用于跨节点查询和跳转。</p>
            <p>* netty-boss-threads：TCP 连接接收线程数，通常设置为 1；修改后需要重启。</p>
            <p>* netty-worker-threads：TCP 网络读写和消息解码线程数；1 核 Pod 设置为 1，2 至 4 核通常设置为 2 至 4；修改后需要重启。</p>
            <p>* report-query-threads：并行读取和合并 Transaction、Event 等报表模型的线程数，不参与消息接收或实时分析；修改后需要重启。</p>
            <p>* max-message-size：单条 TCP 消息允许的最大字节数，默认 4194304（4 MiB）；超限消息会被拒绝，修改后需要重启。</p>
            <p>* graceful-shutdown-timeout-seconds：收到 SIGTERM 后停止 TCP 接收、排空分析队列并最终落盘的最长时间，默认 25 秒；应小于 Pod 的 terminationGracePeriodSeconds。</p>
            <p>* daily-checkpoint-enabled：是否启用每天在线快照；快照不会停止 TCP 接收，也不会关闭当前小时存储。默认 true。</p>
            <p>* daily-checkpoint-hour：每天在线快照的小时，取值 0 至 23，默认 4。</p>
            <p>* daily-checkpoint-minute：每天在线快照的分钟，取值 0 至 59，默认 0。</p>
            <p>* message-processor-thread：将消息写入本地或 HDFS 的持久化线程数，默认 8；每个线程有独立队列，修改后需要重启。</p>
            <p>* message-processor-queue-size：每个持久化线程的队列容量，默认 5000 条；所有队列总容量约等于线程数乘以该值，队列满时新消息会被丢弃。</p>
            <p>* realtime-analyzer-queue-capacity-per-thread：每个实时分析器工作线程的默认队列容量，默认 10000 条；下一个整点创建新分析任务时生效，无需重启。</p>
            <p>* top-analyzer-enable：是否启用监控大盘分析，按分钟汇总各应用的错误类型和错误机器排行。默认 true。</p>
            <p>* business-analyzer-enable：是否启用业务指标分析，聚合客户端上报的 Metric 业务指标。默认 true。</p>
            <p>* matrix-analyzer-enable：是否启用性能报告分析，统计 URL、Service、RPC 等调用的成功率和耗时分布。默认 true。</p>
            <p>* storage-analyzer-enable：是否启用存储调用分析，统计数据库、缓存等调用的次数、耗时和错误情况。默认 true。</p>
            <p>* dependency-analyzer-enable：是否启用服务依赖分析，分析应用与数据库、缓存、服务等下游资源之间的依赖关系。默认 true。</p>

            <p><strong>分析器通用扩展项</strong></p>
            <p>* {name}-analyzer-queue-capacity-per-thread：单独覆盖指定分析器每个线程的队列容量，例如 transaction-analyzer-queue-capacity-per-thread。</p>
            <p>* {name}-analyzer-threads：指定分析器线程数，默认 2；下一个整点创建新分析任务时生效。</p>

            <p><strong>storage / consumer</strong></p>
            <p>* local-base-dir：本地数据存储目录。</p>
            <p>* max-hdfs-storage-time：HDFS 数据最长保留时间，单位为天。</p>
            <p>* local-report-storage-time：本地报表保留时间，单位为天。</p>
            <p>* local-logivew-storage-time：本地原始日志保留时间，单位为天。</p>
            <p>* har-mode：是否启用 HAR 归档模式。</p>
            <p>* upload-thread：上传 HDFS 的并发线程数。</p>
            <p>* hdfs / harfs：远程存储配置；max-size 为文件最大尺寸，server-uri 为服务地址，base-dir 为存储目录。</p>
            <p>* long-config：Transaction、SQL、Service 的默认慢调用阈值；可使用 domain 子项为指定应用单独覆盖。</p>
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
