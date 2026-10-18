locals {
  repo_root = abspath("${path.module}/../../..")
  image     = "crewmeister"
  # Rebuild and reload the image whenever the app code changes
  src_hash = sha1(join("", [
    filesha1("${local.repo_root}/Dockerfile"),
    filesha1("${local.repo_root}/pom.xml"),
    join("", [for f in fileset("${local.repo_root}/src", "**") : filesha1("${local.repo_root}/src/${f}")]),
  ]))
}

# 1. Local cluster. Port mapping + label let the ingress controller
#    receive traffic from your machine.
resource "kind_cluster" "this" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = var.ingress_host_port
      }
    }
  }
}

provider "helm" {
  kubernetes = {
    host                   = kind_cluster.this.endpoint
    client_certificate     = kind_cluster.this.client_certificate
    client_key             = kind_cluster.this.client_key
    cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
  }
}

# 2. Build the app image and load it into the cluster (no registry needed locally)
resource "terraform_data" "image" {
  triggers_replace = [local.src_hash, kind_cluster.this.id]

  provisioner "local-exec" {
    command = "docker build -t ${local.image}:${substr(local.src_hash, 0, 8)} ${local.repo_root} && kind load docker-image ${local.image}:${substr(local.src_hash, 0, 8)} --name ${var.cluster_name}"
  }
}

# 3. Ingress controller (Traefik), pinned to the labelled node via hostPort
resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = "traefik"
  create_namespace = true
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  wait             = true
  timeout          = 300

  values = [yamlencode({
    ports        = { web = { hostPort = 80 } }
    service      = { spec = { type = "NodePort" } }
    nodeSelector = { "ingress-ready" = "true" }
    tolerations  = [{ key = "node-role.kubernetes.io/control-plane", operator = "Exists", effect = "NoSchedule" }]
    providers    = { kubernetesIngress = { publishedService = { enabled = false } } }
  })]

  depends_on = [kind_cluster.this]
}

# 4. The application
module "app" {
  source           = "../../modules/app"
  image_repository = local.image
  image_tag        = substr(local.src_hash, 0, 8)
  ingress_enabled  = true
  ingress_host     = var.app_host

  depends_on = [terraform_data.image, helm_release.traefik]
}
