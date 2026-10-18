output "app_url" {
  value = "http://${var.app_host}${var.ingress_host_port == 80 ? "" : ":${var.ingress_host_port}"}/user?id=1"
}
