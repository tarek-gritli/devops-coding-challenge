output "get_credentials" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_kubernetes_cluster.this.name}"
}

output "ingress_ip_command" {
  value = "kubectl -n traefik get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}
