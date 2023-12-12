# terraform.tfvars - Terraform configuration variables
#
# Copy terraform.tfvars to override.auto.tfvars, then edit override.auto.tfvars
# to customize settings.

forgerock = {
  employee = false

  billing_entity = null

  es_useremail    = null
  es_businessunit = null
  es_ownedby      = null
  es_managedby    = null
  es_zone         = null
}

clusters = {
  tf_cluster_gke_small = {
    enabled = false
    type    = "gke"
    auth = {
      project_id  = null
      credentials = null
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.28"
      release_channel    = "UNSPECIFIED" # "REGULAR"

      enable_monitoring = true
      enable_logging    = true
    }

    location = {
      region = "us-east1"
      zones  = ["us-east1-b", "us-east1-c", "us-east1-d"]
    }

    node_pools = {
      default = {
        type          = "n2-standard-8"
        disk_size_gb  = 50
        initial_count = 3
        min_count     = 3
        max_count     = 6
        meta = {
          #zones           = ["us-east1-b", "us-east1-c", "us-east1-d"]

          disk_type        = "pd-standard" # "pd-ssd"
          min_cpu_platform = ""
          auto_repair      = true
          auto_upgrade     = true
          preemptible      = false
          oauth_scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
          ]
        }
      },
      #extra = {
      #  type          = "n2-standard-8"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicated = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicated"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones           = ["us-east1-b", "us-east1-c", "us-east1-d"]
      #
      #    disk_type        = "pd-standard"  # "pd-ssd"
      #    min_cpu_platform = ""
      #    auto_repair      = true
      #    auto_upgrade     = true
      #    preemptible      = false
      #    oauth_scopes     = [
      #      "https://www.googleapis.com/auth/cloud-platform",
      #    ]
      #  }
      #},
      #extra-ds = {
      #  type          = "n2-standard-8"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicatedDS = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicatedDS"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones           = ["us-east1-b", "us-east1-c", "us-east1-d"]
      #
      #    disk_type        = "pd-ssd"
      #    min_cpu_platform = ""
      #    auto_repair      = true
      #    auto_upgrade     = true
      #    preemptible      = false
      #    oauth_scopes     = [
      #      "https://www.googleapis.com/auth/cloud-platform",
      #    ]
      #  }
      #},
      #extra-arm64 = {
      #  type          = "t2a-standard-8"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  meta = {
      #    #zones           = ["us-east1-b", "us-east1-c", "us-east1-d"]
      #
      #    disk_type        = "pd-standard"  # "pd-ssd"
      #    min_cpu_platform = ""
      #    auto_repair      = true
      #    auto_upgrade     = true
      #    preemptible      = false
      #    oauth_scopes     = [
      #      "https://www.googleapis.com/auth/cloud-platform",
      #    ]
      #  }
      #},
    }

    helm = {
      external-dns = {
        deploy = true
        #values  = <<-EOF
        # Values from tfvars configuration
        #google:
        #  project: <alt_google_cloud_dns_project>
        #EOF
      },
      cert-manager = {
        deploy = true
      },
      ingress-nginx = {
        deploy = true
      },
      haproxy-ingress = {
        deploy = false
      },
      kube-prometheus-stack = {
        deploy = false
      },
      elasticsearch = {
        deploy = false
      },
      logstash = {
        deploy = false
      },
      kibana = {
        deploy = false
      },
      secret-agent = { # Technology preview, not supported
        deploy = false
      },
      identity-platform = { # Technology preview, not supported
        deploy  = false
        version = "7.4"
        values  = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local
        #    tls:
        #      issuer:
        #        name: identity-platform-issuer
        #        kind: Issuer
        #        create:
        #          type: letsencrypt-prod # letsencrypt-staging self-signed
        #          email: "email@domain.com"

        am:
          replicaCount: 2
          resources:
            requests:
              cpu: 2000m
              memory: 4Gi
            limits:
              memory: 4Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 1500m
              memory: 2Gi
            limits:
              memory: 2Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 4Gi
              cpu: 1500m
            limits:
              memory: 6Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 3Gi
              cpu: 2000m
            limits:
              memory: 5Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi
        EOF
      }
    }
  },
  tf_cluster_gke_medium = {
    enabled = false
    type    = "gke"
    auth = {
      project_id  = null
      credentials = null
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.28"
      release_channel    = "UNSPECIFIED" # "REGULAR"

      enable_monitoring = true
      enable_logging    = true
    }

    location = {
      region = "us-east1"
      zones  = ["us-east1-b", "us-east1-c", "us-east1-d"]
    }

    node_pools = {
      default = {
        type          = "c2-standard-30"
        disk_size_gb  = 50
        initial_count = 3
        min_count     = 3
        max_count     = 6
        meta = {
          #zones           = ["us-east1-b", "us-east1-c", "us-east1-d"]

          disk_type        = "pd-standard" # "pd-ssd"
          min_cpu_platform = ""
          auto_repair      = true
          auto_upgrade     = true
          preemptible      = false
          oauth_scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
          ]
        }
      },
      #extra = {
      #  type          = "c2-standard-30"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicated = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicated"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones           = ["us-east1-b", "us-east1-c", "us-east1-d"]
      #
      #    disk_type        = "pd-standard"  # "pd-ssd"
      #    min_cpu_platform = ""
      #    auto_repair      = true
      #    auto_upgrade     = true
      #    preemptible      = false
      #    oauth_scopes     = [
      #      "https://www.googleapis.com/auth/cloud-platform",
      #    ]
      #  }
      #},
      #extra-ds = {
      #  type          = "c2-standard-30"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicatedDS = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicatedDS"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones           = ["us-east1-b", "us-east1-c", "us-east1-d"]
      #
      #    disk_type        = "pd-ssd"
      #    min_cpu_platform = ""
      #    auto_repair      = true
      #    auto_upgrade     = true
      #    preemptible      = false
      #    oauth_scopes     = [
      #      "https://www.googleapis.com/auth/cloud-platform",
      #    ]
      #  }
      #},
      #extra-arm64 = {
      #  type          = "t2a-standard-32"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  meta = {
      #    #zones           = ["us-east1-b", "us-east1-c", "us-east1-d"]
      #
      #    disk_type        = "pd-standard"  # "pd-ssd"
      #    min_cpu_platform = ""
      #    auto_repair      = true
      #    auto_upgrade     = true
      #    preemptible      = false
      #    oauth_scopes     = [
      #      "https://www.googleapis.com/auth/cloud-platform",
      #    ]
      #  }
      #},
    }

    helm = {
      external-dns = {
        deploy = true
        #values  = <<-EOF
        # Values from tfvars configuration
        #google:
        #  project: <alt_google_cloud_dns_project>
        #EOF
      },
      cert-manager = {
        deploy = true
      },
      ingress-nginx = {
        deploy = true
      },
      haproxy-ingress = {
        deploy = false
      },
      kube-prometheus-stack = {
        deploy = false
      },
      elasticsearch = {
        deploy = false
      },
      logstash = {
        deploy = false
      },
      kibana = {
        deploy = false
      },
      secret-agent = { # Technology preview, not supported
        deploy = false
      },
      identity-platform = { # Technology preview, not supported
        deploy  = false
        version = "7.4"
        values  = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local
        #    tls:
        #      issuer:
        #        name: identity-platform-issuer
        #        kind: Issuer
        #        create:
        #          type: letsencrypt-prod # letsencrypt-staging self-signed
        #          email: "email@domain.com"

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 10Gi
            limits:
              memory: 10Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 6Gi
            limits:
              memory: 6Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 1000Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
      }
    }
  },
  tf_cluster_gke_large = {
    enabled = false
    type    = "gke"
    auth = {
      project_id  = null
      credentials = null
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.28"
      release_channel    = "UNSPECIFIED" # "REGULAR"

      enable_monitoring = true
      enable_logging    = true
    }

    location = {
      region = "us-east1"
      zones  = ["us-east1-b", "us-east1-c", "us-east1-d"]
    }

    node_pools = {
      default = {
        type          = "c2-standard-30"
        disk_size_gb  = 50
        initial_count = 3
        min_count     = 3
        max_count     = 6
        meta = {
          #zones            = ["us-east1-b", "us-east1-c", "us-east1-d"]

          disk_type        = "pd-standard" # "pd-ssd"
          min_cpu_platform = ""
          auto_repair      = true
          auto_upgrade     = true
          preemptible      = false
          oauth_scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
          ]
        }
      },
      #extra = {
      #  type          = "c2-standard-30"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicated = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicated"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones            = ["us-east1-b", "us-east1-c", "us-east1-d"]
      #
      #    disk_type         = "pd-standard"  # "pd-ssd"
      #    min_cpu_platform  = ""
      #    auto_repair       = true
      #    auto_upgrade      = true
      #    preemptible       = false
      #    oauth_scopes      = [
      #      "https://www.googleapis.com/auth/cloud-platform",
      #    ]
      #  }
      #},
      #extra-ds = {
      #  type          = "c2-standard-30"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicatedDS = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicatedDS"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones            = ["us-east1-b", "us-east1-c", "us-east1-d"]
      #
      #    disk_type        = "pd-ssd"
      #    min_cpu_platform = ""
      #    auto_repair      = true
      #    auto_upgrade     = true
      #    preemptible      = false
      #    oauth_scopes     = [
      #      "https://www.googleapis.com/auth/cloud-platform",
      #    ]
      #  }
      #},
      #extra-arm64 = {
      #  type          = "t2a-standard-32"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  meta = {
      #    #zones            = ["us-east1-b", "us-east1-c", "us-east1-d"]
      #
      #    disk_type         = "pd-standard"  # "pd-ssd"
      #    min_cpu_platform  = ""
      #    auto_repair       = true
      #    auto_upgrade      = true
      #    preemptible       = false
      #    oauth_scopes      = [
      #      "https://www.googleapis.com/auth/cloud-platform",
      #    ]
      #  }
      #},
    }

    helm = {
      external-dns = {
        deploy = true
        #values  = <<-EOF
        # Values from tfvars configuration
        #google:
        #  project: <alt_google_cloud_dns_project>
        #EOF
      },
      cert-manager = {
        deploy = true
      },
      ingress-nginx = {
        deploy = true
      },
      haproxy-ingress = {
        deploy = false
      },
      kube-prometheus-stack = {
        deploy = false
      },
      elasticsearch = {
        deploy = false
      },
      logstash = {
        deploy = false
      },
      kibana = {
        deploy = false
      },
      secret-agent = { # Technology preview, not supported
        deploy = false
      },
      identity-platform = { # Technology preview, not supported
        deploy  = false
        version = "7.4"
        values  = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local
        #    tls:
        #      issuer:
        #        name: identity-platform-issuer
        #        kind: Issuer
        #        create:
        #          type: letsencrypt-prod # letsencrypt-staging self-signed
        #          email: "email@domain.com"

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 20Gi
            limits:
              memory: 26Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 4Gi
            limits:
              memory: 8Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 21Gi
              cpu: 8000m
            limits:
              memory: 29Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 512Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
      }
    }
  },
  tf_cluster_eks_small = {
    enabled = false
    type    = "eks"
    auth = {
      access_key = null
      secret_key = null
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.28"
    }

    location = {
      region = "us-east-1"
      zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }

    node_pools = {
      default = {
        type          = "m5.2xlarge"
        disk_size_gb  = 50
        initial_count = 3
        min_count     = 3
        max_count     = 6
        meta = {
          #zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
        }
      },
      #extra = {
      #  type          = "m5.2xlarge"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicated = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicated"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
      #  }
      #},
      #extra-ds = {
      #  type          = "m5.2xlarge"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicatedDS = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicatedDS"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
      #  }
      #},
      #extra-arm64 = {
      #  type          = "m6g.2xlarge"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  meta = {
      #    #zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
      #  }
      #},
    }

    helm = {
      external-dns = {
        deploy = true
        values = <<-EOF
        # Values from tfvars configuration
        EOF
      },
      cert-manager = {
        deploy = true
      },
      ingress-nginx = {
        deploy = true
      },
      haproxy-ingress = {
        deploy = false
      },
      kube-prometheus-stack = {
        deploy = false
      },
      elasticsearch = {
        deploy = false
      },
      logstash = {
        deploy = false
      },
      kibana = {
        deploy = false
      },
      secret-agent = { # Technology preview, not supported
        deploy = false
      },
      identity-platform = { # Technology preview, not supported
        deploy  = false
        version = "7.4"
        values  = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local
        #    tls:
        #      issuer:
        #        name: identity-platform-issuer
        #        kind: Issuer
        #        create:
        #          type: letsencrypt-prod # letsencrypt-staging self-signed
        #          email: "email@domain.com"

        am:
          replicaCount: 2
          resources:
            requests:
              cpu: 2000m
              memory: 4Gi
            limits:
              memory: 4Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 1500m
              memory: 2Gi
            limits:
              memory: 2Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 4Gi
              cpu: 1500m
            limits:
              memory: 6Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 3Gi
              cpu: 2000m
            limits:
              memory: 5Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi
        EOF
      }
    }
  },
  tf_cluster_eks_medium = {
    enabled = false
    type    = "eks"
    auth = {
      access_key = null
      secret_key = null
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.28"
    }

    location = {
      region = "us-east-1"
      zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }

    node_pools = {
      default = {
        type          = "c5.9xlarge"
        disk_size_gb  = 50
        initial_count = 3
        min_count     = 3
        max_count     = 6
        meta = {
          #zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
        }
      },
      #extra = {
      #  type          = "c5.9xlarge"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicated = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicated"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
      #  }
      #},
      #extra-ds = {
      #  type          = "c5.9xlarge"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicatedDS = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicatedDS"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
      #  }
      #},
      #extra-arm64 = {
      #  type          = "c6g.12xlarge"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  meta = {
      #    #zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
      #  }
      #},
    }

    helm = {
      external-dns = {
        deploy = true
        values = <<-EOF
        # Values from tfvars configuration
        EOF
      },
      cert-manager = {
        deploy = true
      },
      ingress-nginx = {
        deploy = true
      },
      haproxy-ingress = {
        deploy = false
      },
      kube-prometheus-stack = {
        deploy = false
      },
      elasticsearch = {
        deploy = false
      },
      logstash = {
        deploy = false
      },
      kibana = {
        deploy = false
      },
      secret-agent = { # Technology preview, not supported
        deploy = false
      },
      identity-platform = { # Technology preview, not supported
        deploy  = false
        version = "7.4"
        values  = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local
        #    tls:
        #      issuer:
        #        name: identity-platform-issuer
        #        kind: Issuer
        #        create:
        #          type: letsencrypt-prod # letsencrypt-staging self-signed
        #          email: "email@domain.com"

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 10Gi
            limits:
              memory: 10Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 6Gi
            limits:
              memory: 6Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 1000Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
      }
    }
  },
  tf_cluster_eks_large = {
    enabled = false
    type    = "eks"
    auth = {
      access_key = null
      secret_key = null
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.28"
    }

    location = {
      region = "us-east-1"
      zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }

    node_pools = {
      default = {
        type          = "c5.9xlarge"
        disk_size_gb  = 50
        initial_count = 3
        min_count     = 3
        max_count     = 6
        meta = {
          #zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
        }
      },
      #extra = {
      #  type          = "c5.9xlarge"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicated = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicated"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
      #  }
      #},
      #extra-ds = {
      #  type          = "c5.9xlarge"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicatedDS = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicatedDS"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
      #  }
      #},
      #extra-arm64 = {
      #  type          = "c6g.12xlarge"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  meta = {
      #    #zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
      #  }
      #},
    }

    helm = {
      external-dns = {
        deploy = true
        values = <<-EOF
        # Values from tfvars configuration
        EOF
      },
      cert-manager = {
        deploy = true
      },
      ingress-nginx = {
        deploy = true
      },
      haproxy-ingress = {
        deploy = false
      },
      kube-prometheus-stack = {
        deploy = false
      },
      elasticsearch = {
        deploy = false
      },
      logstash = {
        deploy = false
      },
      kibana = {
        deploy = false
      },
      secret-agent = { # Technology preview, not supported
        deploy = false
      },
      identity-platform = { # Technology preview, not supported
        deploy  = false
        version = "7.4"
        values  = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local
        #    tls:
        #      issuer:
        #        name: identity-platform-issuer
        #        kind: Issuer
        #        create:
        #          type: letsencrypt-prod # letsencrypt-staging self-signed
        #          email: "email@domain.com"

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 20Gi
            limits:
              memory: 26Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 4Gi
            limits:
              memory: 8Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 21Gi
              cpu: 8000m
            limits:
              memory: 29Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 512Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
      }
    }
  },
  tf_cluster_aks_small = {
    enabled = false
    type    = "aks"
    auth = { # Authenticate with 'az login'
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.28"
    }

    location = {
      region = "eastus"
      zones  = ["1", "2", "3"]
    }

    node_pools = {
      default = {
        type          = "Standard_DS4_v2"
        disk_size_gb  = 50
        initial_count = 3
        min_count     = 3
        max_count     = 6
        meta = {
          default_pool = true
        }
      },
      #extra = {
      #  type          = "Standard_DS4_v2"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicated = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicated"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones = ["1", "2", "3"]
      #  }
      #},
      #extra-ds = {
      #  type          = "Standard_DS4_v2"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicatedDS = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicatedDS"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones = ["1", "2", "3"]
      #  }
      #},
      #extra-arm64 = {
      #  type          = "Standard_D8pds_v5""
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  meta = {
      #    #zones = ["1", "2", "3"]
      #  }
      #},
    }

    helm = {
      external-dns = {
        deploy = true
        values = <<-EOF
        # Values from tfvars configuration
        #azure:
        #  resourceGroup: <azure-resource-group-for-dns>
        EOF
      },
      cert-manager = {
        deploy = true
      },
      ingress-nginx = {
        deploy = true
      },
      haproxy-ingress = {
        deploy = false
      },
      kube-prometheus-stack = {
        deploy = false
      },
      elasticsearch = {
        deploy = false
      },
      logstash = {
        deploy = false
      },
      kibana = {
        deploy = false
      },
      secret-agent = { # Technology preview, not supported
        deploy = false
      },
      identity-platform = { # Technology preview, not supported
        deploy  = false
        version = "7.4"
        values  = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local
        #    tls:
        #      issuer:
        #        name: identity-platform-issuer
        #        kind: Issuer
        #        create:
        #          type: letsencrypt-prod # letsencrypt-staging self-signed
        #          email: "email@domain.com"

        am:
          replicaCount: 2
          resources:
            requests:
              cpu: 2000m
              memory: 4Gi
            limits:
              memory: 4Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 1500m
              memory: 2Gi
            limits:
              memory: 2Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 4Gi
              cpu: 1500m
            limits:
              memory: 6Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 3Gi
              cpu: 2000m
            limits:
              memory: 5Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi
        EOF
      }
    }
  },
  tf_cluster_aks_medium = {
    enabled = false
    type    = "aks"
    auth = { # Authenticate with 'az login'
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.28"
    }

    location = {
      region = "eastus"
      zones  = ["1", "2", "3"]
    }

    node_pools = {
      default = {
        type          = "Standard_F32s_v2"
        disk_size_gb  = 50
        initial_count = 3
        min_count     = 3
        max_count     = 6
        meta = {
          default_pool = true
        }
      },
      #extra = {
      #  type          = "Standard_F32s_v2"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicated = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicated"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones = ["1", "2", "3"]
      #  }
      #},
      #extra-ds = {
      #  type          = "Standard_F32s_v2"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicatedDS = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicatedDS"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones = ["1", "2", "3"]
      #  }
      #},
      #extra-arm64 = {
      #  type          = "Standard_D32plds_v5"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  meta = {
      #    #zones = ["1", "2", "3"]
      #  }
      #},
    }

    helm = {
      external-dns = {
        deploy = true
        values = <<-EOF
        # Values from tfvars configuration
        #azure:
        #  resourceGroup: <azure-resource-group-for-dns>
        EOF
      },
      cert-manager = {
        deploy = true
      },
      ingress-nginx = {
        deploy = true
      },
      haproxy-ingress = {
        deploy = false
      },
      kube-prometheus-stack = {
        deploy = false
      },
      elasticsearch = {
        deploy = false
      },
      logstash = {
        deploy = false
      },
      kibana = {
        deploy = false
      },
      secret-agent = { # Technology preview, not supported
        deploy = false
      },
      identity-platform = { # Technology preview, not supported
        deploy  = false
        version = "7.4"
        values  = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local
        #    tls:
        #      issuer:
        #        name: identity-platform-issuer
        #        kind: Issuer
        #        create:
        #          type: letsencrypt-prod # letsencrypt-staging self-signed
        #          email: "email@domain.com"

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 10Gi
            limits:
              memory: 10Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 6Gi
            limits:
              memory: 6Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 1000Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
      }
    }
  },
  tf_cluster_aks_large = {
    enabled = false
    type    = "aks"
    auth = { # Authenticate with 'az login'
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.28"
    }

    location = {
      region = "eastus"
      zones  = ["1", "2", "3"]
    }

    node_pools = {
      default = {
        type          = "Standard_F32s_v2"
        disk_size_gb  = 50
        initial_count = 3
        min_count     = 3
        max_count     = 6
        meta = {
          default_pool = true
        }
      },
      #extra = {
      #  type          = "Standard_F32s_v2"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicated = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicated"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones = ["1", "2", "3"]
      #  }
      #},
      #extra-ds = {
      #  type          = "Standard_F32s_v2"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  labels = {
      #    WorkerDedicatedDS = "true",
      #  }
      #  taints = [
      #    {
      #      key    = "WorkerDedicatedDS"
      #      value  = "true"
      #      effect = "NoSchedule"
      #    },
      #  ]
      #  meta = {
      #    #zones = ["1", "2", "3"]
      #  }
      #},
      #extra-arm64 = {
      #  type          = "Standard_D32plds_v5"
      #  disk_size_gb  = 50
      #  initial_count = 3
      #  min_count     = 3
      #  max_count     = 6
      #  meta = {
      #    #zones = ["1", "2", "3"]
      #  }
      #},
    }

    helm = {
      external-dns = {
        deploy = true
        values = <<-EOF
        # Values from tfvars configuration
        #azure:
        #  resourceGroup: <azure-resource-group-for-dns>
        EOF
      },
      cert-manager = {
        deploy = true
      },
      ingress-nginx = {
        deploy = true
      },
      haproxy-ingress = {
        deploy = false
      },
      kube-prometheus-stack = {
        deploy = false
      },
      elasticsearch = {
        deploy = false
      },
      logstash = {
        deploy = false
      },
      kibana = {
        deploy = false
      },
      secret-agent = { # Technology preview, not supported
        deploy = false
      },
      identity-platform = { # Technology preview, not supported
        deploy  = false
        version = "7.4"
        values  = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local
        #    tls:
        #      issuer:
        #        name: identity-platform-issuer
        #        kind: Issuer
        #        create:
        #          type: letsencrypt-prod # letsencrypt-staging self-signed
        #          email: "email@domain.com"

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 20Gi
            limits:
              memory: 26Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 4Gi
            limits:
              memory: 8Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 21Gi
              cpu: 8000m
            limits:
              memory: 29Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 512Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
      }
    }
  },
}
