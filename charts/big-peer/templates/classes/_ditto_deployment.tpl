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
      {{- if $values.pki.certIssuer }}
      certManager:
        template:
          issuer:
            metadata:
              annotations: {}
              labels: {}
          caCertificate:
            metadata:
              annotations: {}
              labels: {}
            issuerRef:
              group: cert-manager.io
              kind: ClusterIssuer
              name: {{ $values.pki.certIssuer }}
            secretTemplate:
              metadata:
                annotations: {}
                labels: {}
          inBandCertificate:
            metadata:
              annotations: {}
              labels: {}
            issuerRef:
              group: cert-manager.io
              kind: ClusterIssuer
              name: {{ $values.pki.certIssuer }}
            secretTemplate:
              metadata:
                annotations: {}
                labels: {}
          jwtCertificate:
            metadata:
              annotations: {}
              labels: {}
            issuerRef:
              group: cert-manager.io
              kind: ClusterIssuer
              name: {{ $values.pki.certIssuer }}
            secretTemplate:
              metadata:
                annotations: {}
                labels: {}
      {{- else }}
      external:
        caSecretRef:
          name: {{ tpl $values.pki.device.secretName . }}
          certificate: tls.crt
          key: tls.key
          optional: true
        inBandSecretRef:
          name: {{ tpl $values.pki.inband.secretName . }}
          certificate: tls.crt
          key: tls.key
          optional: true
        jwtSecretRef:
          name: {{ tpl $values.pki.jwt.secretName . }}
          certificate: tls.crt
          key: tls.key
          optional: true
      {{- end -}}
      providers: {{ $values.providers }}
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
      {{ if $values.transactions.kafka.external.enabled }}
      external:
        topicName: {{ $values.transactions.kafka.external.topicName }}
        bootstrapServers:
        {{- toYaml $values.transactions.kafka.external.bootstrapServers | nindent 6 }}
      {{ else }}
      strimzi:
        version: {{ $values.transactions.kafka.strimzi.version }}
        replicas: {{ $values.transactions.kafka.strimzi.replicas }}
      {{ end }}
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
