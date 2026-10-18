# Prometheus + Grafana + the operator that provides the ServiceMonitor CRD
resource "helm_release" "monitoring" {
  name             = "monitoring"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "92.10.1"
  wait             = true
  timeout          = 600

  values = [yamlencode({
    # No Alertmanager: nowhere to send notifications locally, alerts show in the Prometheus UI
    alertmanager = { enabled = false }

    # kind does not expose these control-plane endpoints, scraping them only creates false alerts
    kubeEtcd              = { enabled = false }
    kubeScheduler         = { enabled = false }
    kubeControllerManager = { enabled = false }
    kubeProxy             = { enabled = false }

    prometheus = {
      prometheusSpec = {
        # Pick up every ServiceMonitor and rule, not only those labelled with this release
        serviceMonitorSelectorNilUsesHelmValues = false
        ruleSelectorNilUsesHelmValues           = false
      }
    }

    grafana = {
      ingress = {
        enabled          = true
        ingressClassName = "traefik"
        hosts            = ["grafana.localhost"]
      }
    }
  })]

  depends_on = [helm_release.traefik]
}
