<%@ page contentType="text/html; charset=utf-8"%>
<%@ taglib prefix="a" uri="/WEB-INF/app.tld"%>
<%@ taglib prefix="w" uri="http://www.unidal.org/web/core"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="res" uri="http://www.unidal.org/webres"%>
<jsp:useBean id="ctx"	type="com.dianping.cat.report.page.problem.Context"	scope="request" />
<jsp:useBean id="payload"	type="com.dianping.cat.report.page.problem.Payload"	scope="request" />
<jsp:useBean id="model"	type="com.dianping.cat.report.page.problem.Model" scope="request" />

<a:historyReport title="History Report" navUrlPrefix="ip=${model.ipAddress}${payload.queryString}">

	<jsp:attribute name="subtitle">${w:format(payload.historyStartDate,'yyyy-MM-dd HH:mm:ss')} to ${w:format(payload.historyDisplayEndDate,'yyyy-MM-dd HH:mm:ss')}</jsp:attribute>
	<jsp:body>
<table class="machines">
	<tr style="text-align:left">
		<th>&nbsp;[&nbsp;
					<a href="?op=history&domain=${model.domain}&date=${model.date}${payload.queryString}&ip=All&reportType=${payload.reportType}${model.customDate}"
					>All</a>
			&nbsp;]&nbsp; <c:forEach var="ip" items="${model.ips}">
   	  		&nbsp;[&nbsp;
						<a href="?op=history&domain=${model.domain}&ip=${ip}&date=${model.date}${payload.queryString}&reportType=${payload.reportType}${model.customDate}"
						>${ip}</a>
   	 		&nbsp;]&nbsp;
			 </c:forEach>
		</th></tr>

		<tr class="left">
			<th>
				<c:forEach var="group" items="${model.groups}">
				 <c:choose><c:when test="${payload.group eq group}">
		   	  		&nbsp;[&nbsp;
		   	  			<a class='current' href="?op=historyGroupReport&domain=${model.domain}&date=${model.date}&group=${group}${payload.queryString}">${group}</a>
		   	 		&nbsp;]&nbsp;
	   	 		</c:when>
	   	 		<c:otherwise>
		   	  		&nbsp;[&nbsp;
		   	  			<a href="?op=historyGroupReport&domain=${model.domain}&date=${model.date}&group=${group}${payload.queryString}">${group}</a>
		   	 		&nbsp;]&nbsp;
	   	 		</c:otherwise></c:choose>
				 </c:forEach>
			</th>
		</tr>
		<script type="text/javascript" src="/cat/js/appendHostname.js"></script>
		<script type="text/javascript">
			$(document).ready(function() {
				appendHostname(${model.ipToHostnameStr});
				$.each($('table.machines a'),function(index,item){
					var id=$(item).text();
					<c:forEach var="ip" items="${model.groupIps}">
						group = '${ip}';
						if(id.indexOf(group)!=-1){
								$(item).addClass('current');
						}
					</c:forEach>
				});

			});
			</script>

		<tr><th>
		<%@ include file="problemQuery.jsp" %></th>
		<script>
			function longTimeChange(date,domain,ip){
				var customDate ='${model.customDate}';
				var reportType = '${payload.reportType}';
				var longUrlTime=$("#p_longUrl").val();
				var longSqlTime=$("#p_longSql").val();
				var longServiceTime=$("#p_longService").val();
				var longCacheTime=$("#p_longCache").val();
				var longCallTime=$("#p_longCall").val();
				window.location.href="?op=historyGroupReport&domain="+domain+"&ip="+ip+"&date="+date+"&urlThreshold="+longUrlTime+"&sqlThreshold="+longSqlTime+'&reportType='+reportType+customDate+"&serviceThreshold="+longServiceTime
				+"&cacheThreshold="+longCacheTime+"&callThreshold="+longCallTime+"&group=${payload.group}";
			}
		</script>
	</tr>
</table>

<table class="table table-hover table-striped table-condensed" style="width:100%">
	<tr>
		<th width="15%">类型</th>
		<th width="4%">总量</th>
		<th width="30%">状态</th>
		<th width="4%">个数</th>
		<th>样本链接</th>
	</tr>
	<c:forEach var="statistics" items="${model.allStatistics.status}"
		varStatus="typeIndex">
		<tr>
			<td rowspan="${w:size(statistics.value.status)*3}"
				class="top">
				<a href="?op=historyGroupGraph&group=${payload.group}&domain=${model.domain}&date=${model.date}&ip=${model.ipAddress}&reportType=${payload.reportType}&type=${statistics.value.type}${model.customDate}" class="history_graph_link" data-status="${typeIndex.index}">[:: show ::]</a>
				&nbsp;<a href="#" class="${statistics.value.type}">&nbsp;&nbsp;</a>
				&nbsp;&nbsp;${statistics.value.type}
			</td>
			<td rowspan="${w:size(statistics.value.status)*3}"
				class=" top right">${w:format(statistics.value.count,'#,###,###,###,##0')}</td>
			<c:forEach var="status" items="${statistics.value.status}"
				varStatus="index">
				<c:if test="${index.index != 0}">
					<tr>
				</c:if>
				<td >
					<a href="?op=historyGroupGraph&group=${payload.group}&domain=${model.domain}&date=${model.date}&ip=${model.ipAddress}&reportType=${payload.reportType}&type=${statistics.value.type}&status=${status.value.status}${model.customDate}" class="problem_status_graph_link" data-status="${statistics.value.type}${status.value.status}">[:: show ::]</a>
					&nbsp;${status.value.status}
				</td>
				<td class="right"> ${w:format(status.value.count,'#,###,###,###,##0')}</td>
				<td ><c:forEach
						var="links" items="${status.value.links}" varStatus="linkIndex">
						<a href="/cat/r/m/${links}?domain=${model.domain}">${linkIndex.first?'L':(linkIndex.last?'g':'o')}</a>
					</c:forEach></td>

				<c:if test="${index.index != 0}">
				</tr>
				</c:if>
				<tr></tr>
				<tr><td colspan="3" style="display:none"> <div id="${statistics.value.type}${status.value.status}" style="display:none"></div></td></tr>
			</c:forEach>
			</tr>
		<tr></tr>
		<tr class="graphs"><td colspan="5" style="display:none"><div id="${typeIndex.index}" style="display:none"></div></td></tr>
	</c:forEach>
</table>

<res:useJs value="${res.js.local.problemHistory_js}" target="bottom-js" />
</jsp:body>

</a:historyReport>
