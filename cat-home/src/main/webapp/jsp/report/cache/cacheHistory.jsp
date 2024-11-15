<%@ page session="false" language="java" pageEncoding="UTF-8"%>
<%@ page contentType="text/html; charset=utf-8"%>
<%@ taglib prefix="a" uri="/WEB-INF/app.tld"%>
<%@ taglib prefix="w" uri="http://www.unidal.org/web/core"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="res" uri="http://www.unidal.org/webres"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<jsp:useBean id="ctx" type="com.dianping.cat.report.page.cache.Context"
	scope="request" />
<jsp:useBean id="payload"
	type="com.dianping.cat.report.page.cache.Payload" scope="request" />
<jsp:useBean id="model" type="com.dianping.cat.report.page.cache.Model"
	scope="request" />
<c:set var="report" value="${model.report}" />

<a:historyReport
	title="Cache Report${empty payload.type ? '' : ' :: '}<a href='?op=history&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&type=${payload.type}${model.customDate}'>${payload.type}</a>"
	navUrlPrefix="ip=${model.ipAddress}&queryname=${model.queryName}&domain=${model.domain}${empty payload.type ? '' : '&type='}${payload.type}"
	timestamp="${w:format(model.creatTime,'yyyy-MM-dd HH:mm:ss')}">
	<jsp:attribute name="subtitle">${w:format(payload.historyStartDate,'yyyy-MM-dd HH:mm:ss')} to ${w:format(payload.historyDisplayEndDate,'yyyy-MM-dd HH:mm:ss')}</jsp:attribute>
	<jsp:body>
<table class="machines">
	<tr style="text-align: left">
		<th>&nbsp; <c:forEach var="ip" items="${model.ips}">
   	  		&nbsp;[&nbsp;
   	  		<c:choose>
					<c:when test="${model.ipAddress eq ip}">
						<a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&ip=${ip}&date=${model.date}&type=${payload.type}&queryname=${model.queryName}"
									class="current">${ip}</a>
					</c:when>
					<c:otherwise>
						<a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&ip=${ip}&date=${model.date}&type=${payload.type}&queryname=${model.queryName}">${ip}</a>
					</c:otherwise>
				</c:choose>
   	 		&nbsp;]&nbsp;
			 </c:forEach>
		</th>
	</tr>
</table>
	<c:choose>
		<c:when test="${empty payload.type}">
		<table class="table table-hover table-striped table-condensed ">
		<tr>
			<th class="left"><a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&date=${model.date}&ip=${model.ipAddress}&sort=type">类型</a></th>
			<th class="right"><a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&date=${model.date}&ip=${model.ipAddress}&sort=total">总量</a></th>
			<th class="right"><a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&date=${model.date}&ip=${model.ipAddress}&sort=missed">未命中</a></th>
			<th class="right"><a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&date=${model.date}&ip=${model.ipAddress}&sort=hitPercent">命中率(%)</a></th>
			<th class="right"><a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&date=${model.date}&sort=avg">平均耗时</a>(ms)</th>
			<th class="right">QPS</th>
					</tr>
			<c:forEach var="item" items="${model.report.typeItems}"
						varStatus="status">
				<c:set var="e" value="${item.type}" />
				<c:set var="lastIndex" value="${status.index}" />
				<tr class="  right">
					<td style="text-align: left"><a
								href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&date=${model.date}&ip=${model.ipAddress}&type=${e.id}">${e.id}</a></td>
					<td>${w:format(e.totalCount,'#,###,###,###,##0')}</td>
					<td>${w:format(item.missed,'#,###,###,###,##0')}</td>
					<td>${w:format(item.hited,'0.0000%')}</td>
					<td>${w:format(e.avg,'0.0')}</td>
					<td>${w:format(e.tps,'0.0')}</td>
				</tr>
			</c:forEach>
				</table>
		</c:when>
		<c:otherwise>
			<div class="row-fluid">
			<div class="span7">
			<table class="table table-hover table-striped table-condensed ">
			<tr>
								<th class="left" colspan='10'><input type="text"
									name="queryname" id="queryname" size="40" style="height:35px"
									value="${model.queryName}">
		    <input id="queryname" style="WIDTH: 60px;margin-left:-4px;margin-top:-2px"  class="btn btn-sm btn-primary"
									onclick="filterByName('${model.date}','${model.domain}','${model.ipAddress}','${payload.type}')"
									type="submit">
			&nbsp;支持多个字符串查询，例如 SQL|URL，查询结果为包含任一SQL、URL的列
			</th></tr>
			<tr><th>命中率计算方式: 1-missed/Get, 请注意，mGet 不在统计范围之内</th></tr>
			<script>
				function filterByName(date, domain, ip, type) {
					var queryname = $("#queryname").val();
					var customDate = '${model.customDate}';
					var reportType = '${payload.reportType}';
					var type = '${payload.type}';
					window.location.href = "?op=history&domain=" + domain
							+ "&reportType=" + reportType + "&type=" + type
							+ "&date=" + date + "&queryname=" + queryname
							+ "&ip=" + ip + customDate;
				}
			</script>
			<tr>
			<th class="left">
			<a	href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&date=${model.date}&ip=${model.ipAddress}&type=${payload.type}&sort=type&queryname=${model.queryName}">命令</a>
								</th>
			<th class="right"><a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&date=${model.date}&ip=${model.ipAddress}&type=${payload.type}&sort=total&queryname=${model.queryName}">总量</a></th>
			<c:forEach var="item" items="${model.report.methods}" varStatus="status">
				<th class="right"><a href="?domain=${model.domain}&date=${model.date}&ip=${model.ipAddress}&type=${payload.type}&sort=${item}&queryname=${model.queryName}">${item}</a></th>
			</c:forEach>
			<th class="right"><a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&date=${model.date}&ip=${model.ipAddress}&type=${payload.type}&sort=missed&queryname=${model.queryName}">未命中</a></th>
			<th class="right"><a  href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&date=${model.date}&ip=${model.ipAddress}&type=${payload.type}&sort=hitPercent&queryname=${model.queryName}">命中率(%)</a></th>
			<th class="right"><a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}${model.customDate}&date=${model.date}&type=${payload.type}&sort=avg&queryname=${model.queryName}">平均耗时</a>(ms)</th>
			<th class="right">QPS</th>
							</tr>
			<c:forEach var="item" items="${model.report.nameItems}"
								varStatus="status">
				<c:set var="e" value="${item.name}" />
				<c:set var="lastIndex" value="${status.index}" />
				<tr class="  right">
					<td style="text-align: left; word-wrap: break-word; word-break: break-all;">
					${w:shorten(e.id, 80)}</td>
					<td>${w:format(e.totalCount,'#,###,###,###,##0')}</td>
					<c:forEach var="method" items="${model.report.methods}" varStatus="status">
						<c:choose>
						<c:when test="${item.methodCounts[method] != null}">
							<td>${w:format(item.methodCounts[method],'#,###,###,###,##0')}</td>
						</c:when>
						<c:otherwise>
							<td>0</td>
						</c:otherwise>
						</c:choose>
					</c:forEach>
					<td>${item.missed}</td>
					<td>${w:format(item.hited,'0.0000%')}</td>
					<td>${w:format(e.avg,'0.0')}</td>
					<td>${w:format(e.tps,'0.0')}</td>
				</tr>
			</c:forEach>
			</table>
			</div>
				<div class="span5">
					<div id="cacheGraph"></div>
					<script type="text/javascript">
						var data = ${model.pieChart};
						graphPieChart(document.getElementById('cacheGraph'),
								data);
					</script>
				</div>
			</div>
		</c:otherwise>
	</c:choose>
</table>
<font color="white">${lastIndex+1}</font>

</jsp:body>

</a:historyReport>
<script type="text/javascript" src="/cat/js/appendHostname.js"></script>
<script type="text/javascript">
	$(document).ready(function() {
		appendHostname(${model.ipToHostnameStr});
	});
</script>
