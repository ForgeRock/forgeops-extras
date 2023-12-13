# main.tf - cluster module

module "common" {
  source = "../common"

  forgerock = var.forgerock
  cluster   = var.cluster
}

resource "random_id" "cluster" {
  byte_length = 2
}

data "google_project" "cluster" {
}

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

locals {
  cluster_name = replace(var.cluster.meta.cluster_name, "<id>", random_id.cluster.hex)
  project      = trimprefix(data.google_project.cluster.id, "projects/")

  taint_effects = {
    "noschedule"       = "NO_SCHEDULE",
    "prefernoschedule" = "PREFER_NO_SCHEDULE",
    "noexecute"        = "NO_EXECUTE"
  }
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 29.0"

  project_id = var.cluster.auth.project_id
  name       = local.cluster_name
  region     = var.cluster.location.region
  zones      = var.cluster.location.zones
  #network                              = "vpc-01"
  #subnetwork                           = "${var.cluster.location.region}-01"
  network                              = "default"
  subnetwork                           = "default"
  ip_range_pods                        = null
  ip_range_services                    = null
  #ip_range_pods                        = "${var.cluster.location.region}-01-gke-01-pods"
  #ip_range_services                    = "${var.cluster.location.region}-01-gke-01-services"
  http_load_balancing                  = false
  network_policy                       = false
  horizontal_pod_autoscaling           = true
  filestore_csi_driver                 = true
  monitoring_enable_managed_prometheus = false
  deletion_protection                  = false

  monitoring_service = lookup(var.cluster.meta, "enable_monitoring", null) == null ? "monitoring.googleapis.com/kubernetes" : (tobool(lookup(var.cluster.meta, "enable_monitoring", true)) ? "monitoring.googleapis.com/kubernetes" : "none")
  logging_service    = lookup(var.cluster.meta, "enable_logging", null) == null ? "logging.googleapis.com/kubernetes" : (tobool(lookup(var.cluster.meta, "enable_logging", true)) ? "logging.googleapis.com/kubernetes" : "none")

  release_channel         = lookup(var.cluster.meta, "release_channel", null) == null ? "UNSPECIFIED" : lookup(var.cluster.meta, "release_channel", null)
  kubernetes_version      = var.cluster.meta.kubernetes_version
  cluster_resource_labels = module.common.asset_labels

  #cluster_autoscaling = {
  #  enabled             = true
  #  max_cpu_cores       = 10000
  #  min_cpu_cores       = 1
  #  max_memory_gb       = 100000
  #  min_memory_gb       = 1
  #  gpu_resources       = []
  #  auto_repair         = lookup(var.cluster.meta, "auto_repair", null) == null ? true : tobool(lookup(var.cluster.meta, "auto_repair", null))
  #  auto_upgrade        = lookup(var.cluster.meta, "auto_upgrade", null) == null ? true : tobool(lookup(var.cluster.meta, "auto_upgrade", null))
  #  autoscaling_profile = "BALANCED"
  #}

  node_pools = [
    for pool_name, pool in var.cluster["node_pools"] :
    {
      name               = pool_name
      machine_type       = pool.type
      node_locations     = lookup(pool.meta, "zones", null) == null ? "" : join(",", lookup(pool.meta, "zones", null))
      initial_node_count = pool.initial_count
      min_count          = pool.min_count
      max_count          = pool.max_count
      local_ssd_count    = 0
      disk_size_gb       = lookup(pool, "disk_size_gb", null) == null ? 50 : lookup(pool, "disk_size_gb", null)
      disk_type          = lookup(pool.meta, "disk_type", null) == null ? "pd-standard" : lookup(pool.meta, "disk_type", null)
      image_type         = "COS_CONTAINERD"
      min_cpu_platform   = lookup(pool.meta, "min_cpu_platform", null) == null ? "" : lookup(pool.meta, "min_cpu_platform", null)
      enable_gcfs        = true # AKA image streaming
      auto_repair        = lookup(pool.meta, "auto_repair", null) == null ? true : tobool(lookup(pool.meta, "auto_repair", null))
      auto_upgrade       = lookup(pool.meta, "auto_upgrade", null) == null ? true : tobool(lookup(pool.meta, "auto_upgrade", null))
      preemptible        = lookup(pool.meta, "preemptible", null) == null ? false : tobool(lookup(pool.meta, "preemptible", null))
      #service_account           = "project-service-account@<PROJECT ID>.iam.gserviceaccount.com"
      preemptible = false
    }
  ]

  node_pools_oauth_scopes = {
    for pool_name, pool in var.cluster["node_pools"] :
    pool_name => lookup(pool.meta, "oauth_scopes", null) == null ? ["https://www.googleapis.com/auth/cloud-platform"] : lookup(pool.meta, "oauth_scopes", null)
  }

  node_pools_labels = merge(
    {
      all = module.common.asset_labels
    },
    {
      for pool_name, pool in var.cluster["node_pools"] :
      pool_name => lookup(pool, "labels", null) == null ? {} : lookup(pool, "labels", null)
    }
  )

  node_pools_taints = {
    for pool_name, pool in var.cluster["node_pools"] :
    pool_name => lookup(pool, "taints", null) == null ? [] : [
      for taint in(lookup(pool, "taints", null) == null ? [] : lookup(pool, "taints", null)) :
      {
        key    = taint["key"]
        value  = taint["value"]
        effect = lookup(local.taint_effects, lower(taint["effect"]), taint["effect"])
      }
    ]
  }

  node_pools_metadata = {
    #all = module.common.asset_labels
  }

  node_pools_tags = {
    #all = module.common.asset_labels
  }
}
