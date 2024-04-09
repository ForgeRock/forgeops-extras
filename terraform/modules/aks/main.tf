# main.tf - cluster module

module "common" {
  source = "../common"

  forgerock = var.forgerock
  cluster   = var.cluster
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "random_id" "cluster" {
  byte_length = 2
}

locals {
  cluster_name = replace(var.cluster.meta.cluster_name, "<id>", random_id.cluster.hex)
}

resource "random_id" "prefix" {
  byte_length = 8
}

resource "azurerm_resource_group" "main" {
  name = local.cluster_name
  location = var.cluster.location.region

  tags = {
    cluster_name = local.cluster_name
  }
}

# az feature register --name EnableOIDCIssuerPreview --namespace Microsoft.ContainerService
# az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableOIDCIssuerPreview')].{Name:name,State:properties.state}"
#
#resource "azurerm_resource_provider_registration" "main" {
#  name = "Microsoft.ContainerService"
#
#  feature {
#    name       = "EnableOIDCIssuerPreview"
#    registered = true
#  }
#}

resource "azurerm_public_ip" "ingress" {
  name = local.cluster_name
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location

  allocation_method = "Static"
  sku = "Standard"

  tags = {
    cluster_name = local.cluster_name
  }
}

data "azurerm_kubernetes_service_versions" "kubernetes_version" {
    location = azurerm_resource_group.main.location
    version_prefix = var.cluster.meta.kubernetes_version
    include_preview = false

    depends_on = [azurerm_resource_group.main]
}

locals {
  node_pool_names = keys(var.cluster.node_pools)
  default_node_pools = {
    for pool_name in local.node_pool_names:
      pool_name => var.cluster.node_pools[pool_name] if tobool(lookup(var.cluster.node_pools[pool_name].meta, "default_pool", false)) == true
  }
  # An error will be thrown if there isn't exactly one default node pool
  default_node_pool_name = one(keys(local.default_node_pools))
  default_node_pool = local.default_node_pools[local.default_node_pool_name]
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = local.cluster_name
  kubernetes_version  = data.azurerm_kubernetes_service_versions.kubernetes_version.latest_version

  dns_prefix          = local.cluster_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  default_node_pool {
    name                = local.default_node_pool_name
    zones               = lookup(local.default_node_pool.meta, "zones", null) == null ? var.cluster.location.zones : lookup(local.default_node_pool.meta, "zones", null)

    vm_size             = local.default_node_pool.type
    os_disk_size_gb     = lookup(local.default_node_pool, "disk_size_gb", null) == null ? 50 : lookup(local.default_node_pool, "disk_size_gb", null)
    enable_auto_scaling = true
    node_count          = local.default_node_pool.initial_count
    min_count           = local.default_node_pool.min_count
    max_count           = local.default_node_pool.max_count
    node_labels         = lookup(local.default_node_pool, "labels", null) == null ? module.common.asset_labels : merge(module.common.asset_labels, lookup(local.default_node_pool, "labels", null))
    tags                = module.common.asset_labels
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
  }

  http_application_routing_enabled = false

  depends_on = [azurerm_public_ip.ingress, data.azurerm_kubernetes_service_versions.kubernetes_version]

  lifecycle {
    ignore_changes = [kubernetes_version]
  }
}

locals {
  extra_node_pools = {
    for pool_name in local.node_pool_names:
      pool_name => var.cluster.node_pools[pool_name] if tobool(lookup(var.cluster.node_pools[pool_name].meta, "default_pool", false)) != true
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "extra" {
  for_each              = local.extra_node_pools

  name                  = each.key
  zones                 = lookup(each.value.meta, "zones", null) == null ? var.cluster.location.zones : lookup(each.value.meta, "zones", null)
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id

  vm_size               = each.value.type
  os_type               = "Linux"
  os_disk_size_gb       = lookup(each.value, "disk_size_gb", null) == null ? 50 : lookup(each.value, "disk_size_gb", null)

  enable_auto_scaling   = true
  node_count            = each.value.initial_count
  min_count             = each.value.min_count
  max_count             = each.value.max_count

  node_labels           = merge(module.common.asset_labels, lookup(each.value, "labels", null) == null ? {} : lookup(each.value, "labels", null))
  node_taints         = lookup(each.value, "taints", null) == null ? [] : [
    for taint in (lookup(each.value, "taints", null) == null ? []: lookup(each.value, "taints", null)):
      format("%s=%s:%s", taint["key"], taint["value"], taint["effect"])
  ]

  lifecycle {
    ignore_changes = [node_count]
  }
}

