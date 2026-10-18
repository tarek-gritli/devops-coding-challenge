variable "cluster_name" {
  type    = string
  default = "crewmeister"
}

variable "ingress_host_port" {
  type        = number
  default     = 80
  description = "Port on your machine that reaches the ingress controller"
}

variable "app_host" {
  type        = string
  default     = "crewmeister.localhost"
  description = "*.localhost resolves to 127.0.0.1, no /etc/hosts edit needed"
}
