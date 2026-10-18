variable "subscription_id" {
  type        = string
  description = "Azure subscription to deploy into (az account show --query id -o tsv)"
}

variable "location" {
  type    = string
  default = "spaincentral"
}

variable "resource_group_name" {
  type    = string
  default = "crewmeister-rg"
}

variable "cluster_name" {
  type    = string
  default = "crewmeister-aks"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v4"
  description = "2 vCPU / 8 GiB. The monitoring stack needs this much. Free trials restrict sizes per region and have no quota for some families (e.g. Dsv5). The size must be both allowed (the error from AKS lists them) and have quota (az vm list-usage -l <location>)"
}

variable "image_repository" {
  type    = string
  default = "ghcr.io/tarek-gritli/devops-coding-challenge"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Image published by CI. Pin a git SHA tag for a reproducible deployment."
}
