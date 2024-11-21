{{- define "common.app" -}}
  {{- /* Generate named ingresses as required */ -}}
  {{- range $name, $app := .Values.apps }}
    {{- if $app.enabled -}}
      {{- $appValues := $app -}}

      {{- $_ := set $ "ObjectValues" (dict "app" $appValues) -}}
{{ include "common.classes.registryapp" $ }}
      {{- if $app.liveQuery.enabled -}}
        {{- $_ := set $ "ObjectValues" (dict "app" $appValues) }}
{{ include "common.classes.live_query_core" $ }}
{{ include "common.classes.live_query_source" $ }}
{{ include "common.classes.live_query_sink" $ }}
      {{- end -}}
    {{- end }}
  {{- end }}
{{- end }}


