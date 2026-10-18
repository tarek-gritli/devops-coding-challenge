resource "helm_release" "app" {
  name             = "crewmeister"
  namespace        = "crewmeister"
  create_namespace = true
  chart            = "${path.module}/../../../charts/crewmeister"
  wait             = true
  timeout          = 300

  set = [
    {
      name  = "image.repository"
      value = var.image_repository
    },
    {
      name  = "image.tag"
      value = var.image_tag
    },
    {
      name  = "replicaCount"
      value = var.replica_count
    },
    {
      name  = "ingress.enabled"
      value = var.ingress_enabled
    },
    {
      name  = "ingress.className"
      value = var.ingress_class
    },
    {
      name  = "ingress.host"
      value = var.ingress_host
    },
    {
      name  = "serviceMonitor.enabled"
      value = var.service_monitor_enabled
    },
  ]
}
