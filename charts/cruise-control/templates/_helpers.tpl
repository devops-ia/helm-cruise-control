{{/*
Expand the name of the chart.
*/}}
{{- define "cruise-control.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cruise-control.fullname" -}}
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
{{- define "cruise-control.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cruise-control.labels" -}}
helm.sh/chart: {{ include "cruise-control.chart" . }}
{{ include "cruise-control.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cruise-control.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cruise-control.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Ref: https://github.com/aws/karpenter-provider-aws/blob/main/charts/karpenter/templates/_helpers.tpl
Patch the label selector on an object
This template will add a labelSelector using matchLabels to the object referenced at _target if there is no labelSelector specified.
The matchLabels are created with the selectorLabels template.
This works because Helm treats dictionaries as mutable objects and allows passing them by reference.
*/}}
{{- define "cruise-control.patchselectorLabels" -}}
{{- if not (hasKey ._target "labelSelector") }}
{{- $selectorLabels := (include "cruise-control.selectorLabels" .) | fromYaml }}
{{- $_ := set ._target "labelSelector" (dict "matchLabels" $selectorLabels) }}
{{- end }}
{{- end }}

{{/*
Ref: https://github.com/aws/karpenter-provider-aws/blob/main/charts/karpenter/templates/_helpers.tpl
Patch topology spread constraints
This template uses the cruise-control.selectorLabels template to add a labelSelector to topologySpreadConstraints if one isn't specified.
This works because Helm treats dictionaries as mutable objects and allows passing them by reference.
*/}}
{{- define "cruise-control.patchTopologySpreadConstraints" -}}
{{- range $constraint := .Values.topologySpreadConstraints }}
{{- include "cruise-control.patchselectorLabels" (merge (dict "_target" $constraint (include "cruise-control.selectorLabels" $)) $) }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cruise-control.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cruise-control.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account for UI to use
*/}}
{{- define "cruise-control.ui.serviceAccountName" -}}
{{- if .Values.ui.serviceAccount.create }}
{{- default (printf "%s-ui" (include "cruise-control.fullname" .)) .Values.ui.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.ui.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
UI Selector labels
*/}}
{{- define "cruise-control.ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cruise-control.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: ui
{{- end }}

{{/*
UI labels
*/}}
{{- define "cruise-control.ui.labels" -}}
helm.sh/chart: {{ include "cruise-control.chart" . }}
{{ include "cruise-control.ui.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Ref: https://github.com/aws/karpenter-provider-aws/blob/main/charts/karpenter/templates/_helpers.tpl
Patch the label selector on an object for UI
This template will add a labelSelector using matchLabels to the object referenced at _target if there is no labelSelector specified.
The matchLabels are created with the ui.selectorLabels template.
This works because Helm treats dictionaries as mutable objects and allows passing them by reference.
*/}}
{{- define "cruise-control.ui.patchselectorLabels" -}}
{{- if not (hasKey ._target "labelSelector") }}
{{- $selectorLabels := (include "cruise-control.ui.selectorLabels" .) | fromYaml }}
{{- $_ := set ._target "labelSelector" (dict "matchLabels" $selectorLabels) }}
{{- end }}
{{- end }}

{{/*
Ref: https://github.com/aws/karpenter-provider-aws/blob/main/charts/karpenter/templates/_helpers.tpl
Patch topology spread constraints for UI
This template uses the cruise-control.ui.selectorLabels template to add a labelSelector to topologySpreadConstraints if one isn't specified.
This works because Helm treats dictionaries as mutable objects and allows passing them by reference.
*/}}
{{- define "cruise-control.ui.patchTopologySpreadConstraints" -}}
{{- range $constraint := .Values.ui.topologySpreadConstraints }}
{{- include "cruise-control.ui.patchselectorLabels" (merge (dict "_target" $constraint (include "cruise-control.ui.selectorLabels" $)) $) }}
{{- end }}
{{- end }}

{{/*
Create cluster-specific fullname
*/}}
{{- define "cruise-control.cluster.fullname" -}}
{{- $clusterName := .clusterName -}}
{{- $root := .root -}}
{{- printf "%s-%s" (include "cruise-control.fullname" $root) $clusterName | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create cluster-specific selector labels
*/}}
{{- define "cruise-control.cluster.selectorLabels" -}}
{{- $clusterName := .clusterName -}}
{{- $root := .root -}}
app.kubernetes.io/name: {{ include "cruise-control.name" $root }}
app.kubernetes.io/instance: {{ $root.Release.Name }}
cruise-control.cluster: {{ $clusterName }}
{{- end }}

{{/*
Create cluster-specific labels
*/}}
{{- define "cruise-control.cluster.labels" -}}
{{- $clusterName := .clusterName -}}
{{- $root := .root -}}
helm.sh/chart: {{ include "cruise-control.chart" $root }}
{{ include "cruise-control.cluster.selectorLabels" . }}
{{- if $root.Chart.AppVersion }}
app.kubernetes.io/version: {{ $root.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $root.Release.Service }}
{{- end }}

{{/*
Deep merge cluster configuration with defaults
Values from .Values.clusters have priority over clustersDefaults
*/}}
{{- define "cruise-control.cluster.config" -}}
{{- $result := deepCopy .root.Values.clustersDefaults -}}
{{- range $key, $value := .clusterConfig -}}
  {{- if has $key (list "cluster" "capacity" "jaas" "log4j" "config") -}}
    {{- range $k, $v := $value -}}
      {{- if kindIs "map" $v -}}
        {{- $_ := set (index $result $key) $k (mustMergeOverwrite (index (index $result $key) $k | default dict) $v) -}}
      {{- else -}}
        {{- $_ := set (index $result $key) $k $v -}}
      {{- end -}}
    {{- end -}}
  {{- else -}}
    {{- $_ := set $result $key $value -}}
  {{- end -}}
{{- end -}}
{{- $result | toJson -}}
{{- end }}
