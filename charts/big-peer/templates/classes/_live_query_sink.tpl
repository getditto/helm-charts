{{- define "common.classes.live_query_sink" -}}
  {{- $fullname := include "common.names.fullname" . -}}
  {{- $id := .Values.id -}}
  {{- $appValues := .Values.app -}}
  {{- $values := .Values.app -}}
  {{- $dest := dict "enabled" false -}}
  {{- $dest_type := dict "destination_type" "" -}}
  {{- if hasKey . "ObjectValues" -}}
    {{- with .ObjectValues.app -}}
      {{- $appValues = . -}}
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
  {{- end -}}
---
apiVersion: cloud.app.ditto.live/v1alpha2
kind: LiveQuerySink
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
        sourceTopicName: {{ $appValues.id }}
        url: {{ $dest.url | quote }}
    {{- end }}
  liveQueryCoreRef:
    name: {{ $appValues.id }}
    namespace: {{ .Release.Namespace }}
  liveQuerySourceRef:
    name: {{ $appValues.id }}
    namespace: {{ .Release.Namespace }}
{{- end }}

{{- define "common.classes.live_query_sinks"}}
  {{- $appValues := .Values.app -}}
  {{- if hasKey . "ObjectValues" }}
    {{- with .ObjectValues.app }}
      {{- $appValues = . }}
    {{- end }}
  {{- end }}


  {{- range $type, $sink := $appValues.liveQuery.sinks }}
    {{- $ObjectValues := dict "app" $appValues "sink" $sink "sink_type" $type }}

    {{- $_ := set $ "ObjectValues" $ObjectValues }}
    {{- if and $sink.enabled }}
{{ include "common.classes.live_query_sink" $ }}
    {{- end }}
  {{- end }}
{{- end}}
