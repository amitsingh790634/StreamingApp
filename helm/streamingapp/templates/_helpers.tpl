{{/*
Expand the name of the chart.
*/}}
{{- define "streamingapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "streamingapp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label.
*/}}
{{- define "streamingapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "streamingapp.labels" -}}
helm.sh/chart: {{ include "streamingapp.chart" . }}
{{ include "streamingapp.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "streamingapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "streamingapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component labels for a named service.
*/}}
{{- define "streamingapp.componentLabels" -}}
{{ include "streamingapp.labels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Resolve an image reference from values.
*/}}
{{- define "streamingapp.image" -}}
{{- $registry := .root.Values.imageRegistry -}}
{{- $repository := .repository -}}
{{- $tag := .tag -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}

{{/*
Mongo connection string used by every backend service.
*/}}
{{- define "streamingapp.mongoUri" -}}
{{- printf "mongodb://%s:%v/%s" .Values.mongo.serviceName .Values.mongo.port .Values.mongo.database }}
{{- end }}
