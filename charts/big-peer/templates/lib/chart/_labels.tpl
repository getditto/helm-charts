{{/* Common labels shared across objects */}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.names.chart" . }}
{{ include "common.labels.selectorLabels" . }}
  {{- if hasKey . "ObjectValues" }}
  {{- with .ObjectValues.app }}
{{ include "common.labels.registryApp" . }}
  {{ end }}
  {{- end }}
  {{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
  {{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
  {{- with .Values.global.labels }}
    {{- range $k, $v := . }}
      {{- $name := $k }}
      {{- $value := tpl $v $ }}
{{ $name }}: {{ quote $value }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/* Selector labels shared across objects */}}
{{- define "common.labels.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "common.labels.registryApp" -}}
cloud.app.ditto.live/app-id: {{ .id | quote }}
cloud.app.ditto.live/org-url: {{ .organizationUrl | default "not_used" | quote }}
cloud.app.ditto.live/app-slug: {{ .slug | default .id | quote }}
{{- end }}
