{{- define "cat.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cat.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cat.module.name" -}}
{{- default .Release.Name .Values.moduleName | trunc 52 | trimSuffix "-" -}}
{{- end -}}

{{- define "cat.mysql.name" -}}
{{- printf "%s-mysql" (include "cat.module.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cat.server.name" -}}
{{- printf "%s-server" (include "cat.module.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cat.server.headlessName" -}}
{{- printf "%s-headless" (include "cat.server.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cat.secret.name" -}}
{{- printf "%s-secret" (include "cat.module.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cat.module.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cat.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "cat.module.labels" -}}
helm.sh/chart: {{ include "cat.chart" . }}
{{ include "cat.module.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "cat.mysql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cat.mysql.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "cat.server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cat.server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "cat.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "cat.module.name" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "cat.mysql.host" -}}
{{- if .Values.cat.server.mysql.host -}}
{{- .Values.cat.server.mysql.host -}}
{{- else if .Values.cat.mysql.enabled -}}
{{- include "cat.mysql.name" . -}}
{{- else -}}
{{- required "cat.server.mysql.host is required when cat.mysql.enabled=false" .Values.cat.server.mysql.host -}}
{{- end -}}
{{- end -}}

{{- define "cat.mysql.schema" -}}
{{- default .Values.cat.mysql.database .Values.cat.server.mysql.schema -}}
{{- end -}}

{{- define "cat.server.url" -}}
{{- if .Values.cat.server.serverUrl -}}
{{- .Values.cat.server.serverUrl -}}
{{- else -}}
{{- printf "%s.%s.svc.%s" (include "cat.server.headlessName" .) .Release.Namespace .Values.clusterDomain -}}
{{- end -}}
{{- end -}}
