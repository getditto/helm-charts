{{- define "common.classes.live_query_sink" -}}
  {{- $fullname := include "common.names.fullname" . -}}
  {{- $id := .Values.id -}}
  {{- $appValues := .Values.app -}}
  {{- $values := .Values.app -}}
  {{- $queryValues := .Values.query -}}
  {{- $dest := dict "enabled" false -}}
  {{- $dest_type := dict "destination_type" "" -}}
  {{- $source_name := .ObjectValues.source_name -}}
  {{- if hasKey . "ObjectValues" -}}
    {{- with .ObjectValues.app -}}
      {{- $appValues = . -}}
    {{- end -}}

    {{- with .ObjectValues.query -}}
      {{- $queryValues = . -}}
    {{- end -}}

    {{- with .ObjectValues.sink -}}
      {{- $dest = . -}}
    {{- end -}}
    {{- with .ObjectValues.sink_type -}}
      {{- $dest_type = . -}}
    {{- end -}}
  {{ end -}}

  {{- if and (hasKey $appValues "nameOverride") $appValues.nameOverride -}}
    {{- $app = $appValues.nameOverride -}}
  {{ end -}}
---
apiVersion: cloud.app.ditto.live/v1alpha2
kind: LiveQuerySink
metadata:
  name: {{ uuidv4 }}
  {{- with (merge ($values.labels | default dict) (include "common.labels" $ | fromYaml)) }}
  labels: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with (merge ($values.annotations | default dict) (include "common.annotations" $ | fromYaml)) }}
  annotations: {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  appId: {{ $appValues.id }}
  description: null
  destination:
    {{- if eq $dest_type "kafka" }}
    kafkaConsumer:
      cluster:
        name: {{ .Release.Name }}-live-query-kafka
        namespace: {{ .Release.Namespace }} 
      consumerGroup: user-consumable-{{ $appValues.id }}
      topicName: user-consumable-{{ $appValues.id }}
    {{- end }}
    {{- if eq $dest_type "webhook" }}
      webhook:
        sourceTopicName: {{ $source_name }}
        url: {{ $dest.url | quote }}
    {{- end }}
  liveQueryCoreRef:
    name: {{ $appValues.id }}
    namespace: {{ .Release.Namespace }}
  liveQuerySourceRef:
    name: {{ $source_name }}
    namespace: {{ .Release.Namespace }}
{{- end }}

{{- define "common.classes.live_query_sinks"}}
  {{- $appValues := .Values.app -}}
  {{- $queryValues := .Values.query -}}
  {{- if hasKey . "ObjectValues" }}
    {{- with .ObjectValues.app }}
      {{- $appValues = . }}
    {{- end }}
    {{- with .ObjectValues.query }}
      {{- $queryValues = . }}
    {{- end }}
  {{- end }}


  {{- range $type, $sink := $queryValues.sinks }}
    {{- $ObjectValues := dict "app" $appValues "sink" $sink "sink_type" $type "query" $queryValues "source_name" $.ObjectValues.source_name }}

    {{- $_ := set $ "ObjectValues" $ObjectValues }}
    {{- if and $sink.enabled }}
{{ include "common.classes.live_query_sink" $ }}
    {{- end }}
  {{- end }}
{{- end}}
