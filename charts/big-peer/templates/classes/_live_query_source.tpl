{{- define "common.classes.live_query_source" -}}
  {{- $fullname := include "common.names.fullname" . -}}
  {{- $id := .Values.id -}}
  {{- $appValues := .Values.app -}}
  {{- $values := .Values.app -}}
  {{- $source_name := .ObjectValues.source_name -}}
  {{- if hasKey . "ObjectValues" -}}
    {{- with .ObjectValues.app -}}
      {{- $appValues = . -}}
    {{- end -}}
  {{ end -}}

{{- $queryValues := .Values.query -}}
{{- if hasKey . "ObjectValues" -}}
  {{- with .ObjectValues.query -}}
    {{- $queryValues = . -}}
  {{- end -}}
{{ end -}}


  {{- $values := $appValues.liveQuery -}}
  {{- if and (hasKey $appValues "nameOverride") $appValues.nameOverride -}}
    {{- $app = $appValues.nameOverride -}}
  {{ end }}
---
apiVersion: cloud.app.ditto.live/v1alpha2
kind: LiveQuerySource
metadata:
  name: {{ $source_name }}
  {{- with (merge ($values.labels | default dict) (include "common.labels" $ | fromYaml)) }}
  labels: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with (merge ($values.annotations | default dict) (include "common.annotations" $ | fromYaml)) }}
  annotations: {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  appId: {{ $appValues.id }}
  description: null
  collection: null 
  liveQueryCoreRef:
    name: {{ $appValues.id }}
    namespace: {{ .Release.Namespace }}
  output:
    kafka:
      cluster:
        name: {{ .Release.Name }}-live-query-kafka
        namespace: {{ .Release.Namespace }} 
      topicName: {{ include "common.topics.name" (dict "id" $appValues.id "queryName" $queryValues.name) }}
  queryFilterExpression: {{ $queryValues.queryFilterExpression | quote }}
  schema: {{ $queryValues.schema }}
{{- end }}
