{{/*
Add custom env variables 
*/}}
{{- define "cap.env" -}}
    {{- if . -}}
        {{- range $name, $value := . }}
- name: {{ $name | quote }}
  value: {{ $value | quote }}
        {{- end -}}
    {{- end -}}
{{- end -}}

{{/*
Get list of deployment names
*/}}
{{- define "cap.deploymentNames" -}}
{{- $ := . -}}
{{- $defaultDeployments := (list "srv") -}}
  {{- if $.Values.sidecar -}}
{{-   $defaultDeployments = (append $defaultDeployments "sidecar") -}}
  {{- end -}}
  {{- if $.Values.approuter -}}
{{-   $defaultDeployments = (append $defaultDeployments "approuter") -}}
  {{- end -}}
{{ .deploymentNames | default $defaultDeployments | join ";" }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.

copied from web-application: web-application.fullname

*/}}
{{- define "cap.deploymentHost" -}}
{{- if .deployment.expose.host }}
{{- .deployment.expose.host }}
{{- else }}
{{- $name := (include "cap.web-application.fullname" .) }}
{{- if hasPrefix $name .Release.Namespace }}
{{- .Release.Namespace }}
{{- else }}
{{- printf "%s-%s" $name .Release.Namespace | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "cap.web-application.fullname" -}}
{{- if .deployment.fullnameOverride }}
{{- .deployment.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .name .deployment.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Get FQDN of a deployment
*/}}
{{- define "cap.deploymentHostFull" -}}
{{ include "cap.deploymentHost" $ }}.{{ $.Values.global.domain }}
{{- end -}}

{{/*
Backend Destinations
*/}}
{{- define "cap.approuterDestinations" -}}
{{- $ := . -}}
{{- if $.Values.approuterDestinations }}
{{- $destinations := list -}}
{{- range $destinationName, $destination := $.Values.approuterDestinations -}}
    {{- $destination := merge (dict "name" $destinationName) $destination -}}
    {{- $deployment := (get $.Values $destination.service) -}}
    {{- $srv := merge (dict "name" $destination.service "destination" $destination "deployment" $deployment) $ -}}
    {{- $destinationHost := include "cap.deploymentHostFull" $srv -}}
    {{- $currentDestination := dict "name" $destination.name "forwardAuthToken" true "url" (print  "https://" $destinationHost ) -}}
    {{- $destinations = (append $destinations $currentDestination) -}}
{{- end -}}
{{- $destinations | toJson }}
{{- end -}}
{{- end -}}