provider "azurerm" {
  features {}
  subscription_id = var.subscription_id

  # azurerm 5.x no longer registers resource providers itself, a fresh subscription needs these for AKS
  resource_providers_to_register = [
    "Microsoft.ContainerService",
    "Microsoft.Compute",
    "Microsoft.Network",
    "Microsoft.Storage",
  ]
}

# Only this machine's public IP may reach the Kubernetes API by default.
# Terraform's Helm provider needs API access during the apply, so the range must include the caller.
data "http" "my_ip" {
  count = var.api_server_authorized_ip_ranges == null ? 1 : 0
  url   = "https://api.ipify.org"
}

locals {
  api_authorized_ip_ranges = var.api_server_authorized_ip_ranges != null ? var.api_server_authorized_ip_ranges : ["${chomp(data.http.my_ip[0].response_body)}/32"]
}

# 1. Cluster. Free control-plane tier, only the nodes cost money.
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = var.cluster_name
  sku_tier            = "Free"

  # RBAC is the default, stated explicitly so it is visible (and to static scanners)
  role_based_access_control_enabled = true

  api_server_access_profile {
    authorized_ip_ranges = local.api_authorized_ip_ranges
  }

  # Azure CNI Overlay with the Cilium data plane, which also provides network policy enforcement.
  # No NetworkPolicy objects are defined, so all pod traffic is still allowed.
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
  }

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size

    # Azure fills these defaults in, declaring them avoids a perpetual diff
    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # required since azurerm 5.0. Manual: we size the node pool ourselves, no node auto-provisioning
  node_provisioning_profile {
    mode               = "Manual"
    default_node_pools = "None"
  }
}

provider "helm" {
  kubernetes = {
    host                   = azurerm_kubernetes_cluster.this.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate)
  }
}

# 2. Ingress controller. Its LoadBalancer Service gets a public Azure IP.
resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = "traefik"
  create_namespace = true
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  wait             = true
  timeout          = 600

  values = [yamlencode({
    # Azure's load balancer probes HTTP and needs a 200, Traefik answers 404 on "/",
    # so expose Traefik's /ping on the web entrypoint and probe that instead
    service      = { annotations = { "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/ping" } }
    ingressRoute = { healthcheck = { enabled = true, entryPoints = ["web"] } }
  })]

  depends_on = [azurerm_kubernetes_cluster.this]
}

# 3. Monitoring: Prometheus and Grafana, Grafana stays private (port-forward)
module "monitoring" {
  source = "../../modules/monitoring"

  depends_on = [azurerm_kubernetes_cluster.this]
}

# 4. The application, image comes from the public GHCR package built by CI
module "app" {
  source                  = "../../modules/app"
  image_repository        = var.image_repository
  image_tag               = var.image_tag
  ingress_enabled         = true # no host: the rule matches the ingress IP directly
  service_monitor_enabled = true

  depends_on = [helm_release.traefik, module.monitoring]
}
