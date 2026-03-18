{{/*
Expand the name of the chart.
*/}}
{{- define "chatassistant.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
Uses "insurance-claim" as the base name per naming convention.
*/}}
{{- define "chatassistant.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "insurance-claim" .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chatassistant.labels" -}}
helm.sh/chart: {{ include "chatassistant.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: insurance-claim
{{- end }}

{{/*
Selector labels for a component
*/}}
{{- define "chatassistant.selectorLabels" -}}
app.kubernetes.io/name: {{ .component }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
NGC image pull secret name
*/}}
{{- define "chatassistant.imagePullSecretName" -}}
{{ include "chatassistant.fullname" . }}-ngc-pull
{{- end }}

{{/*
NVIDIA API secret name
*/}}
{{- define "chatassistant.nvidiaSecretName" -}}
{{ include "chatassistant.fullname" . }}-nvidia-api
{{- end }}

{{/*
Application secrets name (LLM, EMBED, RAIL keys)
*/}}
{{- define "chatassistant.appSecretName" -}}
{{ include "chatassistant.fullname" . }}-app-secrets
{{- end }}

{{/*
OpenShift SecurityContext for non-root containers (pod level)
*/}}
{{- define "chatassistant.securityContext" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{/*
OpenShift container-level SecurityContext
*/}}
{{- define "chatassistant.containerSecurityContext" -}}
allowPrivilegeEscalation: false
capabilities:
  drop: [ "ALL" ]
{{- end }}

{{/*
TopologySpreadConstraints — spread GPU pods across nodes
*/}}
{{- define "chatassistant.gpuTopologySpread" -}}
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        insurance-claim/gpu-workload: "true"
{{- end }}

{{/*
Anti-affinity — prevent heavy NIM services from landing on the same node.
*/}}
{{- define "chatassistant.nimAntiAffinity" -}}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: insurance-claim/nim-heavy
                operator: In
                values: [ "true" ]
              - key: app.kubernetes.io/name
                operator: NotIn
                values: [ "{{ .component }}" ]
          topologyKey: kubernetes.io/hostname
{{- end }}
