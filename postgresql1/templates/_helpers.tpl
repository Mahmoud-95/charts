{{/*
Expand the name of the chart.
*/}}
{{- define "postgresql.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "postgresql.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 20 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 20 | trimSuffix "-" -}}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 20 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "postgresql.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}




{{/*
Common labels
*/}}
{{- define "postgresql.labels" -}}
helm.sh/chart: {{ include "postgresql.chart" . }}
{{ include "postgresql.selectorLabels" . }}
{{- end }}



{{/*
Selector labels
*/}}
{{- define "postgresql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "postgresql.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "postgresql.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "postgresql.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the name for a custom user to create
*/}}
{{- define "postgresql.username" -}}
{{- if .Values.global -}}
    {{- if .Values.global.postgresql -}}
        {{- if .Values.global.postgresql.auth.user -}}
            {{- .Values.global.postgresql.auth.user -}}
        {{- else -}}
            {{- .Values.postgresql.auth.user -}}
        {{- end -}}
    {{- else -}}
        {{- .Values.postgresql.auth.user -}}
    {{- end -}}
{{- else -}}
    {{- .Values.postgresql.auth.user -}}
{{- end -}}
{{- end -}}

{{/*
Return the name for a custom database to create
*/}}
{{- define "postgresql.database" -}}
{{- $postgresqlDatabase := default "postgres" .Values.postgresql.auth.database -}}
{{- if .Values.global -}}
    {{- if .Values.global.postgresql -}}
        {{- if .Values.global.postgresql.auth.database -}}
            {{- default "postgres" .Values.global.postgresql.auth.database -}}
        {{- else -}}
            {{- $postgresqlDatabase -}}
        {{- end -}}
    {{- else -}}
        {{- $postgresqlDatabase -}}
    {{- end -}}
{{- else -}}
    {{- $postgresqlDatabase -}}
{{- end -}}
{{- end -}}

{{/* vim: set filetype=mustache: */}}
{{/*
Return  the proper Storage Class
{{ include "common.storage.class" ( dict "persistence" .Values.path.to.the.persistence "global" $) }}
*/}}
{{- define "postgresql.storageclass" -}}
{{- $postgresqlstorageClass := default "" .Values.postgresql.persistence.storageClass -}}
{{- if .Values.global -}}
    {{- if .Values.global.postgresql -}}
        {{- if .Values.global.postgresql.storageClass -}}
            {{- default "" .Values.global.postgresql.storageClass -}}
        {{- else -}}
            {{- $postgresqlstorageClass -}}
        {{- end -}}
    {{- else -}}
        {{- $postgresqlstorageClass -}}
    {{- end -}}
{{- else -}}
    {{- $postgresqlstorageClass -}}
{{- end -}}
{{- end -}}

{{/*
Return the name for a custom user to create
*/}}
{{- define "postgresql.password" -}}
{{- $postgresqlPassword := default "postgres" .Values.postgresql.auth.password -}}
{{- if .Values.global -}}
    {{- if .Values.global.postgresql -}}
        {{- if .Values.global.postgresql.auth.password -}}
            {{- default "postgres" .Values.global.postgresql.auth.password -}}
        {{- else -}}
            {{- $postgresqlPassword -}}
        {{- end -}}
    {{- else -}}
        {{- $postgresqlPassword -}}
    {{- end -}}
{{- else -}}
    {{- $postgresqlPassword -}}
{{- end -}}
{{- end -}}


