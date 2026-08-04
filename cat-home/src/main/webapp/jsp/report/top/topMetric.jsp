<%@ page contentType="text/html; charset=utf-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<style>
	.tooltip-inner {
		max-width: 36555px;
	}
	.top-metric-grid {
		display: flex;
		flex-wrap: wrap;
		align-items: flex-start;
		gap: 12px;
		margin: 14px 8px;
	}
	.top-metric-card {
		min-width: 150px;
		font-size: 13px;
		background: #fff;
		border: 1px solid #e7edf3;
		border-radius: 5px;
		border-spacing: 0;
		box-shadow: 0 1px 2px rgba(30, 55, 80, 0.05);
		overflow: hidden;
	}
	.top-metric-card th,
	.top-metric-card td {
		padding: 6px 9px;
		border: 0;
		border-bottom: 1px solid #f0f3f6;
		line-height: 20px;
	}
	.top-metric-card tr:last-child td {
		border-bottom: 0;
	}
	.top-metric-card .metric-time {
		color: #c45b4d;
		font-weight: 600;
		background: #fafbfd;
	}
	.top-metric-card .metric-column-heading {
		color: #4f5f6f;
		font-weight: 600;
		background: #fcfdfe;
	}
	.top-metric-card .metric-count {
		width: 42px;
		text-align: right;
		white-space: nowrap;
	}
	.top-metric-card .metric-normal td {
		background-color: #f7f9fb;
		color: #6c757d;
	}
	.top-metric-card .metric-warning td {
		background-color: #fff8e5;
		color: #8a6d20;
	}
	.top-metric-card .metric-danger td {
		background-color: #fcebec;
		color: #a94442;
	}
	.top-metric-card .metric-normal a { color: #5f6f7f; }
	.top-metric-card .metric-warning a { color: #8a6d20; }
	.top-metric-card .metric-danger a { color: #a94442; }
</style>
<script type="text/javascript">
	$('.hreftip').tooltip({container:'body', html:true, delay:{show:0, hide:0}});
</script>

<c:if test="${not empty model.message}">
	<h3 class="text-center text-danger">CAT服务端异常:${model.message}</h3>
</c:if>
<c:if test="${ empty model.message}">
	<h3 class="text-center text-success">CAT服务端正常</h3>
</c:if>

<c:set var="date" value="${w:format(model.topReport.startTime,'yyyyMMddHH')}"/>
<div class="top-metric-grid">
	<c:forEach var="item" items="${model.topMetric.error.result}" varStatus="itemStatus">
		<table class="top-metric-card">
			<thead>
				<tr><th colspan="2" class="metric-time">${item.key}</th></tr>
				<tr class="metric-column-heading"><th>系统</th><th class="metric-count">数量</th></tr>
			</thead>
			<tbody>
				<c:forEach var="detail" items="${item.value}" varStatus="status">
					<c:choose>
						<c:when test="${detail.alert == 2}"><c:set var="rowClass" value="metric-danger"/></c:when>
						<c:when test="${detail.alert == 1}"><c:set var="rowClass" value="metric-warning"/></c:when>
						<c:otherwise><c:set var="rowClass" value="metric-normal"/></c:otherwise>
					</c:choose>
					<tr class="${rowClass}">
						<td><a class="hreftip" href="/cat/r/p?domain=${detail.domain}&date=${date}" title="${detail.errorInfo}">${w:shorten(detail.domain, 18)}</a></td>
						<td class="metric-count">${w:format(detail.value,'0')}</td>
					</tr>
				</c:forEach>
			</tbody>
		</table>
	</c:forEach>
</div>
