{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "keycloak.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate to 20 characters because this is used to set the node identifier in WildFly which is limited to
23 characters. This allows for a replica suffix for up to 99 replicas.
*/}}
{{- define "keycloak.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 20 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 20 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 20 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "keycloak.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "keycloak.labels" -}}
helm.sh/chart: {{ include "keycloak.chart" . }}
{{ include "keycloak.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "keycloak.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keycloak.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "keycloak.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "keycloak.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name for the postgres requirement.
*/}}
{{- define "keycloak.postgresql.fullname" -}}
{{- $postgresContext := dict "Values" .Values.postgresql "Release" .Release "Chart" (dict "Name" "postgresql") -}}
{{ include "keycloak.fullname" .}}-{{ include "postgresql.name" $postgresContext }}
{{- end }}

{{/*
Create the service DNS name.
*/}}
{{- define "keycloak.serviceDnsName" -}}
{{ include "keycloak.fullname" . }}-headless.{{ .Release.Namespace }}.svc.{{ .Values.clusterDomain }}
{{- end }}

{{/*
Create secret admin name.
*/}}

{{- define "keycloak.secretAdmin" -}}
{{ include "keycloak.fullname" . }}-admin.{{ .Release.Namespace }}
{{- end }}

{{/*
   keycloak env
*/}}
{{- define "keycloak.env" }}
- name: KUBERNETES_NAMESPACE
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: metadata.namespace
- name: MY_POD_NAME
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: metadata.name
- name: KEYCLOAK_ADMIN
  valueFrom:
    secretKeyRef:
      name: {{ include "keycloak.secretAdmin" . }}
      key: KEYCLOAK_ADMIN
- name: KEYCLOAK_ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "keycloak.secretAdmin" . }}
      key: KEYCLOAK_ADMIN_PASSWORD
{{- if and (.Values.http.relativePath) (eq .Values.http.relativePath "/")  }}
- name: KC_HTTP_RELATIVE_PATH
  value: {{ tpl .Values.http.relativePath $ }}
{{ else }}
- name: KC_HTTP_RELATIVE_PATH
  value: {{ tpl .Values.http.relativePath $ | trimSuffix "/" }}
{{- end }}
{{- if eq .Values.cache.stack "default" }}
- name: KC_CACHE
  value: "ispn"
- name: KC_CACHE_STACK
  value: "kubernetes"
{{- end }}
{{- if .Values.proxy.enabled }}
- name: KC_PROXY
  value: {{ .Values.proxy.mode }}
{{- end }}
- name: KC_HOSTNAME_STRICT
  value: "false"
- name: KC_HOSTNAME_STRICT_HTTPS
  value: "false"
- name: KC_HTTP_ENABLED
  value: "true"
- name: KC_METRICS_ENABLED
  value: "true"
- name: KC_HEALTH_ENABLED
  value: "true"
- name: KEYCLOAK_STATISTICS
  value: all
{{- if .Values.postgresql.enabled }}
- name: KC_DB
  value: postgres
- name: KC_DB_URL_HOST
  value: {{ include "keycloak.postgresql.fullname" . }}
- name: KC_DB_URL_PORT
  value: {{ .Values.postgresql.service.port | quote }}
- name: KC_DB_URL_DATABASE
  value: {{ .Values.postgresql.auth.database  }}
- name: KC_DB_USERNAME
  value: {{ .Values.postgresql.auth.user  }}
- name: KC_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "keycloak.postgresql.fullname" . }}
      key: password
{{- end }}

- name: JGROUPS_DISCOVERY_PROTOCOL
  value: dns.DNS_PING
- name: JGROUPS_DISCOVERY_PROPERTIES
  value: "dns_query={{ include "keycloak.serviceDnsName" . }}"
- name: jgroups.dns.query
  value: {{ include "keycloak.serviceDnsName" . }}
- name: JAVA_OPTS_APPEND
  value: >-
      -Djgroups.dns.query={{ include "keycloak.fullname" . }}-headless
      -XX:+UseContainerSupport
      -XX:MaxRAMPercentage=50.0
      -Djava.awt.headless=true
      -Dkubeping_namespace={{ .Release.Namespace }}
      -Dkubeping_label="keycloak-cluster=default"
- name: CACHE_OWNERS_COUNT
  value: "2"
- name: CACHE_OWNERS_AUTH_SESSIONS_COUNT
  value: "2"
- name: PROXY_ADDRESS_FORWARDING
  value: "true"

{{- if .Values.configurations }}
- name: KEYCLOAK_IMPORT
  value: /realm/realm.json
{{- end }}
{{- end }}

{{/*
   keycloak ports
*/}}
{{- define "keycloak.ports" }}
- name: http
  containerPort: 8080
  protocol: TCP
- name: https
  containerPort: 8443
  protocol: TCP
{{- end }}

{{/*
   keycloak.init_container.check_db
*/}}
{{- define "keycloak.init_container.check_db" }}
- name: pgchecker
  image: "{{ .Values.pgchecker.image.repository }}:{{ .Values.pgchecker.image.tag }}"
  imagePullPolicy: {{ .Values.pgchecker.image.pullPolicy }}
  securityContext:
    {{- toYaml .Values.pgchecker.securityContext | nindent 12 }}
  command:
    - sh
    - -c
    - |
      echo 'Waiting for PostgreSQL to become ready...'
      until printf "." && nc -z -w 2 {{ include "keycloak.postgresql.fullname" . }} {{ .Values.postgresql.service.port }}; do
          sleep 2;
      done;
      echo 'PostgreSQL OK ✓'
  resources:
    {{- toYaml .Values.pgchecker.resources | nindent 12 }}
{{- end }}


