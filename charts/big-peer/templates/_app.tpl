{{- define "common.app" -}}
  {{- /* Generate named ingresses as required */ -}}
  {{- range $name, $app := .Values.apps }}
    {{- if $app.enabled -}}
      {{- $appValues := $app -}}

      {{- $_ := set $ "ObjectValues" (dict "app" $appValues) -}}
{{ include "common.classes.registryapp" $ }}
      {{- if $app.liveQuery.enabled -}}
{{ include "common.classes.live_query_core" $ }}
{{- range $query := $app.liveQuery.queries }}
  {{- if $query.enabled }}
  {{- $_ := set $ "ObjectValues" (dict "app" $appValues "query" $query "source_name" (include "common.topics.name" (dict "id" $appValues.id "queryName" $query.name))) -}}
{{ include "common.classes.live_query_source" $ }}
{{ include "common.classes.live_query_sinks" $ }}
  {{- end }}
{{- end }}
      {{- end -}}
    {{- end }}
  {{- end }}
{{- end }}


