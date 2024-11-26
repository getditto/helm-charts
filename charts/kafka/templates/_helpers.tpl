{{/*
Expand the name of the chart.
*/}}
{{- define "kafka.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kafka.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kafka.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kafka.sharedLabels" -}}
helm.sh/chart: {{ include "kafka.chart" . }}
app.ditto.live/service-group: kafka
app.ditto.live/exposed: "{{ .Values.strimzi.externalListener.enabled }}"
app.ditto.live/repo: "ditto"
app.ditto.live/tier: {{ get .Values.nodeSelector "app.ditto.live/tier" | default "unset" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kafka.labels" -}}
{{ include "kafka.sharedLabels" . }}
{{ include "kafka.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Entity Operator labels
*/}}
{{- define "kafka.entityOperatorLabels" -}}
{{ include "kafka.sharedLabels" . }}
{{- if .Values.entityOperatorLabels }}
{{ toYaml .Values.entityOperatorLabels | indent 4 }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kafka.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kafka.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kafka.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kafka.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "kafka.nodeAffinity" -}}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
      - matchExpressions:
        - key: "app.ditto.live/tier"
          operator: In
          values:
          - {{ get $.Values.nodeSelector "app.ditto.live/tier" }}
{{- end -}}

{{- define "kafka.podAntiAffinity" -}}
{{- $name := index . 0 -}}
{{- $zoneAntiAffinityType := index . 1 -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
    ## spread across multiple hosts
    - podAffinityTerm:
        labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
                - {{ $name }}
        topologyKey: kubernetes.io/hostname
      weight: 100
  {{- if eq $zoneAntiAffinityType "soft" }}
    ## spread across zones if possible
    - podAffinityTerm:
        labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
                - {{ $name }}
        topologyKey: topology.kubernetes.io/zone
      weight: 100
  {{- else if eq $zoneAntiAffinityType "hard" }}
  requiredDuringSchedulingIgnoredDuringExecution:
    ## spread across zones
    - labelSelector:
        matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
              - {{ $name }}
      topologyKey: topology.kubernetes.io/zone
  {{- end }}
{{- end -}}
