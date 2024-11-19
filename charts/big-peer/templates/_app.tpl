{{- define "common.app" -}}
  {{- /* Generate named ingresses as required */ -}}
  {{- range $name, $app := .Values.apps }}
    {{- if $app.enabled -}}
      {{- $appValues := $app -}}

      {{- $_ := set $ "ObjectValues" (dict "app" $appValues) -}}
      {{- include "common.classes.registryapp" $ }}
    {{- end }}
  {{- end }}
{{- end }}


