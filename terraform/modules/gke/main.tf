# main.tf - cluster module

module "common" {
  source = "../common"

  forgerock = var.forgerock
  cluster   = var.cluster
}

resource "random_id" "cluster" {
  byte_length = 2
}

locals {
  cluster_name = replace(var.cluster.meta.cluster_name, "<id>", random_id.cluster.hex)
}

data "google_project" "cluster" {
}

locals {
  project = trimprefix(data.google_project.cluster.id, "projects/")
}

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

module "gke" {
  source                               = "terraform-google-modules/kubernetes-engine/google"
  version                              = "~> 25.0"

  project_id                           = var.cluster.auth.project_id
  name                                 = local.cluster_name
  region                               = var.cluster.location.region
  zones                                = var.cluster.location.zones
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

  monitoring_service                   = lookup(var.cluster.meta, "enable_monitoring", true) == true ? "monitoring.googleapis.com/kubernetes" : "none"
  logging_service                      = lookup(var.cluster.meta, "enable_logging", true) == true ? "logging.googleapis.com/kubernetes" : "none"

  release_channel                      = lookup(var.cluster.meta, "release_channel", null)
  kubernetes_version                   = var.cluster.meta.kubernetes_version
  cluster_resource_labels              = module.common.asset_labels

  cluster_autoscaling = {
    enabled             = true
    max_cpu_cores       = 10000
    min_cpu_cores       = 1
    max_memory_gb       = 100000
    min_memory_gb       = 1
    gpu_resources       = []
    auto_repair         = lookup(var.cluster.meta, "auto_repair", true)
    auto_upgrade        = lookup(var.cluster.meta, "auto_upgrade", true)
    autoscaling_profile = "BALANCED"
  }

  node_pools = [
    for pool_name, pool in var.cluster["node_pools"]:
      {
        name                      = pool_name
        machine_type              = pool.type
        #node_locations            = "us-central1-b,us-central1-c"
        initial_node_count        = pool.initial_count
        min_count                 = pool.min_count
        max_count                 = pool.max_count
        local_ssd_count           = 0
        disk_size_gb              = lookup(pool, "disk_size_gb", 50)
        disk_type                 = "pd-ssd"
        image_type                = "COS_CONTAINERD"
        min_cpu_platform          = lookup(pool.meta, "min_cpu_platform", "")
        enable_gcfs               = true  # AKA image streaming
        auto_repair               = lookup(pool.meta, "auto_repair", true)
        auto_upgrade              = lookup(pool.meta, "auto_upgrade", true)
        #service_account           = "project-service-account@<PROJECT ID>.iam.gserviceaccount.com"
        preemptible               = false
      }
  ]

  node_pools_oauth_scopes = {
    for pool_name, pool in var.cluster["node_pools"]:
      pool_name => lookup(pool.meta, "oauth_scopes", ["https://www.googleapis.com/auth/cloud-platform"])
  }

  node_pools_labels = {
  }

  node_pools_metadata = {
  }

  node_pools_taints = {
  }

  node_pools_tags = {
  }
}

