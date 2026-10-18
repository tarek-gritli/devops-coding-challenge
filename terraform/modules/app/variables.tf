variable "image_repository" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "replica_count" {
  type    = number
  default = 2
}

variable "ingress_enabled" {
  type    = bool
  default = false
}

variable "ingress_class" {
  type    = string
  default = "traefik"
}

variable "ingress_host" {
  type    = string
  default = ""
}

variable "service_monitor_enabled" {
  type    = bool
  default = false
}
