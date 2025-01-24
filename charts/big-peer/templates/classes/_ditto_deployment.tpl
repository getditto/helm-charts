{{- define "common.bigpeer" -}}
  {{- /* Generate big peer deployment config driven by ditto operator */ -}}
  {{- $fullname := include "common.names.fullname" . -}}
  {{- $values := index .Values "ditto-deployment" -}}
  {{- $storageClassName := default "local-path" $values.storage.storage_class_name -}}
---
apiVersion: ditto.live/v1alpha1
kind: BigPeer
metadata:
  name: {{ $values.name | default "big-peer" }}
spec:
  version: {{ $values.version | default "1.40.3" }}
  image:
    namePrefix: {{ $values.image.namePrefix }}
    pullPolicy: {{ $values.image.pullPolicy | default "IfNotPresent" }}
    pullSecrets: {{ $values.image.pullSecrets | default "[]" }}
  network:
    hostname: {{ if (($values.network).hostname) }}{{ $values.network.hostname }}{{ else }}localhost{{ end }}
  auth:
    keys:
      ca:
        secretRef:
          name: {{ tpl $values.pki.device.secretName . }}
          certificate: tls.crt
          key: tls.key
          optional: true
      inBand:
        secretRef:
          name: {{ tpl $values.pki.inband.secretName . }}
          certificate: tls.crt
          key: tls.key
          optional: true
      jwt:
        secretRef:
          name: {{ tpl $values.pki.jwt.secretName . }}
          certificate: tls.crt
          key: tls.key
          optional: true
    providers:
      {{- toYaml $values.providers | nindent 6 }}
  api:
    image: {{ $values.image.namePrefix }}/big-peer-subscription:{{ $values.version }}
    imagePullPolicy: {{ $values.image.pullPolicy }}
    imagePullSecrets: []
    resources:
      limits:
        cpu: 2000m
        memory: 4Gi
      requests:
        cpu: 100m
        memory: 256Mi
    storage:
      storage_class_name: {{ $storageClassName }}
      size: 10Gi
    replicas: 1
  subscriptions:
    image: {{ $values.image.namePrefix }}/big-peer-subscription:{{ $values.version }}
    imagePullPolicy: {{ $values.image.pullPolicy }}
    imagePullSecrets: []
    resources:
      limits:
        cpu: 2000m
        memory: 4Gi
      requests:
        cpu: 100m
        memory: 256Mi
    storage:
      storage_class_name: {{ $storageClassName }}
      size: 10Gi
    replicas: 1
  store:
    image: {{ $values.image.namePrefix }}/big-peer-store:{{ $values.version }}
    imagePullPolicy: {{ $values.image.pullPolicy }}
    imagePullSecrets: []
    resources:
      limits:
        cpu: 2000m
        memory: 4Gi
      requests:
        cpu: 100m
        memory: 256Mi
    storage:
      storage_class_name: {{ $storageClassName }}
      size: 10Gi
    partitions: 2
    replicas: 1
    hashingScheme: ByDocumentId
  transactions:
    kafka:
      bootstrapHost: {{ $values.transactions.kafka.bootstrapHost }}
---
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: {{ $values.transactions.kafka.topic.name }}
  labels:
    strimzi.io/cluster: {{ tpl .Release.Name . }}-kafka
spec:
  partitions: {{ $values.transactions.kafka.topic.partitions }}
  replicas: {{ $values.transactions.kafka.topic.replicas }}
  config:
    cleanup.policy: delete
    max.message.bytes: 104857600
{{- end }}
