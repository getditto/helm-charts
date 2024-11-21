{{- define "common.classes.live_query_core" -}}
  {{- $fullname := include "common.names.fullname" . -}}
  {{- $appValues := .Values.app -}}
  {{- if hasKey . "ObjectValues" -}}
    {{- with .ObjectValues.app -}}
      {{- $appValues = . -}}
    {{- end -}}
  {{ end -}}

  {{- $values := $appValues.liveQuery -}}
  {{- if and (hasKey $appValues "nameOverride") $appValues.nameOverride -}}
    {{- $app = $appValues.nameOverride -}}
  {{ end -}}

  {{ $id := .Values.id }}
---
apiVersion: cloud.app.ditto.live/v1alpha2
kind: LiveQueryCore
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
  cdcKafkaClusterRef:
    name: {{ .Release.Name }}-live-query-kafka
    namespace: {{ .Release.Namespace }} 
  description: null
  httpApiServerPoolRef:
    name: {{ .Release.Name }}hydra-subscription-api
    namespace: {{.Release.Namespace}}
  hydraClusterRef:
    name: {{ .Release.Name }}-hydra-store
    namespace: {{ .Release.Namespace }}
  subscriptionPoolRef:
    name: {{ .Release.Name }}-hydra-subscription
    namespace: {{ .Release.Namespace }}
{{- end }}
