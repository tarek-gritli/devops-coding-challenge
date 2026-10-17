{{- define "cm.name" -}}{{ .Release.Name }}-crewmeister{{- end -}}
{{- define "cm.mysql" -}}{{ .Release.Name }}-mysql{{- end -}}
{{- define "cm.host" -}}{{ if .Values.mysql.enabled }}{{ include "cm.mysql" . }}{{ else }}{{ .Values.externalDatabase.host }}{{ end }}{{- end -}}
{{- define "cm.db" -}}{{ if .Values.mysql.enabled }}{{ .Values.mysql.database }}{{ else }}{{ .Values.externalDatabase.database }}{{ end }}{{- end -}}
{{- define "cm.labels" -}}
app.kubernetes.io/name: crewmeister
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
