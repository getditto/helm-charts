{{- define "common.topics.name" -}}
  {{- printf "%s-%s" .id .queryName | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}


