<%@ page contentType="text/html; charset=utf-8"%>
<%@ taglib prefix="a" uri="/WEB-INF/app.tld"%>
<%@ taglib prefix="w" uri="http://www.unidal.org/web/core"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="res" uri="http://www.unidal.org/webres"%>
<jsp:useBean id="ctx" type="com.dianping.cat.report.page.cross.Context" scope="request" />
<jsp:useBean id="payload"  	type="com.dianping.cat.report.page.cross.Payload" scope="request" />
<jsp:useBean id="model" type="com.dianping.cat.report.page.cross.Model" scope="request" />

<a:historyReport title="Cross Report"
	navUrlPrefix="ip=${model.ipAddress}&domain=${model.domain}">
	<jsp:attribute name="subtitle">${w:format(payload.historyStartDate,'yyyy-MM-dd HH:mm:ss')} to ${w:format(payload.historyDisplayEndDate,'yyyy-MM-dd HH:mm:ss')}</jsp:attribute>
	<jsp:body>
<%@ include file="crossQuery.jsp" %>
<table class="machines">
	<tr style="text-align: left">
		<th>&nbsp;[&nbsp; <c:choose>
				<c:when test="${model.ipAddress eq 'All'}">
					<a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&project=${payload.projectName}${model.customDate}"
								class="current">All</a>
				</c:when>
				<c:otherwise>
					<a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&project=${payload.projectName}${model.customDate}">All</a>
				</c:otherwise>
			</c:choose> &nbsp;]&nbsp; <c:forEach var="ip" items="${model.ips}">
   	  		&nbsp;[&nbsp;
   	  		<c:choose>
					<c:when test="${model.ipAddress eq ip}">
						<a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}&ip=${ip}&date=${model.date}&project=${payload.projectName}${model.customDate}"
									class="current">${ip}</a>
					</c:when>
					<c:otherwise>
						<a href="?op=history&domain=${model.domain}&reportType=${payload.reportType}&ip=${ip}&date=${model.date}&project=${payload.projectName}${model.customDate}">${ip}</a>
					</c:otherwise>
				</c:choose>
   	 		&nbsp;]&nbsp;
			 </c:forEach>
		</th>
	</tr>
</table>
<script type="text/javascript" src="/cat/js/appendHostname.js"></script>
<script type="text/javascript">
	$(document).ready(function() {
		appendHostname(${model.ipToHostnameStr});
	});
</script>
<table class='table table-striped table-condensed '>
		<c:if test="${!empty model.hostInfo.callProjectsInfo}">
		<tr><td colspan="7" style="text-align:center"><strong>调用其他RPC服务</strong></td></tr>
		<tr>
			<th class="left">Type</th>
			<th class="left"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&serviceSort=${model.serviceSort}&callSort=name${model.customDate}">RemoteId</a></th>
			<th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&serviceSort=${model.serviceSort}&callSort=total${model.customDate}">总量</a></th>
			<th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&serviceSort=${model.serviceSort}&callSort=failure${model.customDate}">失败次数</a></th>
			<th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&serviceSort=${model.serviceSort}&callSort=failurePercent${model.customDate}">错误率</a></th>
			<th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&serviceSort=${model.serviceSort}&callSort=avg${model.customDate}">平均耗时(ms)</a></th>
			<th class="right">QPS</th>
		</tr>
		<c:forEach var="callInfo" items="${model.hostInfo.callProjectsInfo}" varStatus="status">
			<tr class=" right">
		         	<td class="left">${callInfo.type}</td>
		         	<td class="left"><a href="?op=historyMethod&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&remote=${callInfo.ip }&project=${payload.projectName}${model.customDate}">${callInfo.ip}</a></td>
		            <td>${w:format(callInfo.totalCount,'#,###,###,###,##0')}</td>
		         	<td>${w:format(callInfo.failureCount,'#,###,###,###,##0')}</td>
		        	<td>${w:format(callInfo.failurePercent,'0.0000%')}</td>
		             <td>${w:format(callInfo.avg,'0.00')}</td>
		             <td>${w:format(callInfo.tps,'0.00')}</td>
		         </tr>
		</c:forEach>
		</c:if>
		<c:if test="${!empty model.hostInfo.serviceProjectsInfo}">
			<tr><td colspan="7" style="text-align:center"><strong>提供RPC服务 [ 服务器端数据 ]</strong></td>
			<c:if test="${!empty model.hostInfo.callerProjectsInfo}">
				<td></td>
				<td colspan="7" style="text-align:center"><strong>提供RPC服务 [ 客户端数据 ]</strong></td>
			</c:if>
			</tr>
		      <tr>
		         <th class="left">Type</th>
		         <th class="left"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&callSort=${model.callSort}&serviceSort=name${model.customDate}">RemoteId</a></th>
		         <th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&callSort=${model.callSort}&serviceSort=total${model.customDate}">总量</a></th>
		         <th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&callSort=${model.callSort}&serviceSort=failure${model.customDate}">失败次数</a></th>
		         <th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&callSort=${model.callSort}&serviceSort=failurePercent${model.customDate}">错误率</a></th>
		         <th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&callSort=${model.callSort}&serviceSort=avg${model.customDate}">平均耗时(ms)</a></th>
		         <th class="right">QPS</th>
		         <c:if test="${!empty model.hostInfo.callerProjectsInfo}">
		         	 <th></th>
			         <th class="left">Type</th>
			         <th class="left"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&callSort=${model.callSort}&serviceSort=name${model.customDate}">RemoteId</a></th>
			         <th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&callSort=${model.callSort}&serviceSort=total${model.customDate}">总量</a></th>
			         <th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&callSort=${model.callSort}&serviceSort=failure${model.customDate}">失败次数</a></th>
			         <th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&callSort=${model.callSort}&serviceSort=failurePercent${model.customDate}">错误率</a></th>
			         <th class="right"><a href="?op=historyHost&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&project=${payload.projectName}&callSort=${model.callSort}&serviceSort=avg${model.customDate}">平均耗时(ms)</a></th>
			         <th class="right">QPS</th>
		         </c:if>
		      </tr>
		      <c:forEach var="serviceInfo" items="${model.hostInfo.serviceProjectsInfo}" varStatus="status">
		         <tr class=" right">
		            <td class="left">${serviceInfo.type}</td>
		            <td class="left"><a href="?op=historyMethod&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&remote=${serviceInfo.ip}&project=${payload.projectName}${model.customDate}">${serviceInfo.ip}</a></td>
		            <td>${w:format(serviceInfo.totalCount,'#,###,###,###,##0')}</td>
		            <td>${w:format(serviceInfo.failureCount,'#,###,###,###,##0')}</td>
		            <td>${w:format(serviceInfo.failurePercent,'0.0000%')}</td>
		            <td>${w:format(serviceInfo.avg,'0.00')}</td>
		            <td>${w:format(serviceInfo.tps,'0.00')}</td>
		            <c:set var="ip" value="${serviceInfo.ip}"/>
		            <c:set var="callerInfo" value="${model.hostInfo.callerProjectsInfo}"/>
		            <c:if test="${!empty callerInfo}">
		            	<td></td>
			            <td class="left">${callerInfo[ip].type}</td>
		            	<td class="left"><a href="?op=historyMethod&domain=${model.domain}&reportType=${payload.reportType}&date=${model.date}&ip=${model.ipAddress}&remote=${callerInfo[ip].ip}&project=${payload.projectName}${model.customDate}">${callerInfo[ip].ip}</a></td>
		            	<td>${w:format(callerInfo[ip].totalCount,'#,###,###,###,##0')}</td>
		            	<td>${w:format(callerInfo[ip].failureCount,'#,###,###,###,##0')}</td>
		            	<td>${w:format(callerInfo[ip].failurePercent,'0.0000%')}</td>
		             	<td>${w:format(callerInfo[ip].avg,'0.00')}</td>
		             	<td>${w:format(callerInfo[ip].tps,'0.00')}</td>
		            </c:if>
		         </tr>
		      </c:forEach>
		      </c:if>
</table>
</jsp:body>
</a:historyReport>
