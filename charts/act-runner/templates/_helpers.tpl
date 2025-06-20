{{/*
Expand the name of the chart.
*/}}
{{- define "act_runner.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "act_runner.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.global.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "act_runner.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "act_runner.labels" -}}
helm.sh/chart: {{ include "act_runner.chart" . }}
{{ include "act_runner.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- if .Values.global.commonLabels }}
{{ toYaml .Values.global.commonLabels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "act_runner.selectorLabels" -}}
app.kubernetes.io/name: {{ include "act_runner.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "act_runner.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "act_runner.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Helper template to determine the Docker image tag based on the mode.
Usage: {{ include "act_runner.imageTag" . }}
*/}}
{{- define "act_runner.imageTag" -}}
{{- if .Values.runner.dockerDind.enabled -}}
{{ .Values.image.tag | default .Chart.AppVersion }}
{{- else -}}
{{ .Values.image.tag | default .Chart.AppVersion }}-dind-rootless
{{- end -}}
{{- end -}}

{{/*
Helper template to determine the secret reference for act_runner token.
Usage:
  secretRef:
    name: {{ include "act_runner.tokenSecretName" . }}
    key:  {{ include "act_runner.tokenSecretKey" . }}
*/}}
{{- define "act_runner.tokenSecretName" -}}
{{- if .Values.runner.token.fromSecret.name -}}
{{ .Values.runner.token.fromSecret.name }}
{{- else -}}
{{ include "act_runner.fullname" . }}-secret
{{- end -}}
{{- end -}}

{{- define "act_runner.tokenSecretKey" -}}
{{- if .Values.runner.token.fromSecret.key -}}
{{ .Values.runner.token.fromSecret.key }}
{{- else -}}
act-runner-token
{{- end -}}
{{- end -}}

{{/*
Helper template to determine the persistent volume claim for the act_runner pod.
Usage: {{ include "act_runner.claimName" . }}
*/}}
{{- define "act_runner.claimName" -}}
{{- if .Values.persistence.existingClaim -}}
{{ .Values.persistence.existingClaim }}
{{- else -}}
{{ include "act_runner.fullname" . }}-pvc
{{- end -}}
{{- end -}}

{{/*
Helper template to determine the configMap for the act_runner pod.
Usage: {{ include "act_runner.configMap" . }}
*/}}
{{- define "act_runner.configMap" -}}
{{ include "act_runner.fullname" . }}-config
{{- end -}}

{{/*
Helper template to build the securityContext, adding privileged: true if dockerDind is enabled.
Usage: securityContext: {{ include "act_runner.securityContext" . | nindent 2 }}
*/}}
{{- define "act_runner.securityContext" -}}
{{- $base := .Values.securityContext | default dict -}}
{{- if not .Values.runner.dockerDind.enabled -}}
{{- $merged := merge (dict "privileged" true) $base -}}
{{- toYaml $merged -}}
{{- else -}}
{{- toYaml $base -}}
{{- end -}}
{{- end -}}

{{/*
Merges default PVC annotations with .Values.serviceAccount.annotations.
Usage:
  annotations: {{ include "act_runner.pvcAnnotations" . | nindent 4 }}
*/}}
{{- define "act_runner.pvcAnnotations" -}}
{{- $default := dict "helm.sh/resource-policy" "keep" -}}
{{- $annotations := merge $default (.Values.serviceAccount.annotations | default dict) -}}
{{- toYaml $annotations -}}
{{- end -}}

{{/*
Helper template for deployment pod annotations in act_runner.
Usage:
  annotations: {{ include "act_runner.podAnnotations" . | nindent 4 }}
*/}}

{{- define "act_runner.podAnnotations" -}}
{{- $annotations := dict "checksum/secret" (tpl (toYaml .Values.runner.token.value) . | sha256sum) -}}
{{- if .Values.runner.config.enabled -}}
  {{- $_ := set $annotations "checksum/config" (tpl (toYaml .Values.runner.config.data) . | sha256sum) -}}
{{- end -}}
{{- range $k, $v := (.Values.podAnnotations | default dict) -}}
  {{- $_ := set $annotations $k $v -}}
{{- end -}}
{{- toYaml $annotations -}}
{{- end -}}
