# outputs.tf - cluster module outputs

locals {
  kube_config = {
    "config_path"            = "~/.kube/config-tf.aks.${var.cluster.location.region}.${local.cluster_name}"
    "host" = azurerm_kubernetes_cluster.cluster.kube_config[0].host,
    "cluster_ca_certificate" = azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate,
    "client_certificate"     = azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate,
    "client_key"             = azurerm_kubernetes_cluster.cluster.kube_config[0].client_key,
    "token"                  = null
  }
}

output "kube_config" {
  value = local.kube_config
}

resource "local_file" "kube_config" {
  filename             = pathexpand(local.kube_config["config_path"])
  file_permission      = "0600"
  directory_permission = "0775"
  content              = azurerm_kubernetes_cluster.cluster.kube_config_raw
}

data "azurerm_kubernetes_cluster" "cluster" {
  name                = var.cluster.meta.cluster_name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_kubernetes_cluster.cluster]
}

module "common-output" {
  source = "../common-output"

  cluster       = merge(var.cluster, {type = "AKS", meta = {cluster_name = local.cluster_name, kubernetes_version = data.azurerm_kubernetes_cluster.cluster.kubernetes_version}})
  kube_config   = local.kube_config
  helm_metadata = module.helm.metadata

  depends_on = [module.helm]
}

output "cluster_info" {
  value = module.common-output.cluster_info
}

