{{- define "common.classes.live_query_source" -}}
  {{- $fullname := include "common.names.fullname" . -}}
  {{- $id := .Values.id -}}
  {{- $appValues := .Values.app -}}
  {{- $values := .Values.app -}}
  {{- if hasKey . "ObjectValues" -}}
    {{- with .ObjectValues.app -}}
      {{- $appValues = . -}}
    {{- end -}}
  {{ end -}}

  {{- $values := $appValues.liveQuery -}}
  {{- if and (hasKey $appValues "nameOverride") $appValues.nameOverride -}}
    {{- $app = $appValues.nameOverride -}}
  {{- end -}}
---
apiVersion: cloud.app.ditto.live/v1alpha2
kind: LiveQuerySource
metadata:
  name: {{ $appValues.id }}
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
      topicName: user-consumable-{{ $appValues.id }}
  queryFilterExpression: {{ $values.queryFilterExpression | quote }}
  schema: {{ $values.schema }}
{{- end }}
