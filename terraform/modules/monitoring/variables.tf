variable "grafana_host" {
  type        = string
  default     = ""
  description = "Hostname to expose Grafana on through the ingress. Empty keeps Grafana private (use kubectl port-forward)."
}
