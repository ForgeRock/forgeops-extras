# main.tf - root module

locals {
  backend = local.backends[keys(local.backends)[0]]
  backend_type = local.backend.type
  backend_args = join("\n", compact([
    for key, value in local.backend.args:
      value != null ? format("    %s = \"%s\"", key, value) : null
  ]))
}

resource "null_resource" "backend" {
  triggers = {
    config = jsonencode(local.backend)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      cat > ${path.module}/backend.tf <<EOF
terraform {
  backend "${local.backend_type}" {
${local.backend_args}
  }
}
EOF
      echo "backend.tf created successfully."
    EOT
  }

  lifecycle {
    precondition {
      condition = length(local.backends) == 1
      error_message = "Exactly one backend must be enabled."
    }
  }
}

resource "null_resource" "clusters" {
  triggers = {
    config = jsonencode(local.clusters)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      cat > ${path.module}/clusters.tf <<EOF
### GKE ####
%{ for key in keys(local.clusters.gke) }
provider "google" {
  alias       = "${key}"

  region      = local.clusters.gke["${key}"].location["region"]
  project     = local.clusters.gke["${key}"].auth["project_id"]
  credentials = local.clusters.gke["${key}"].auth["credentials"]
}

provider "kubernetes" {
  alias                  = "${key}"

  host                   = module.${key}.kube_config["host"]
  cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
  client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
  client_key             = module.${key}.kube_config["client_key"]
  token                  = module.${key}.kube_config["token"]
}

provider "helm" {
  alias = "${key}"

  kubernetes = {
    host                   = module.${key}.kube_config["host"]
    cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
    client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
    client_key             = module.${key}.kube_config["client_key"]
    token                  = module.${key}.kube_config["token"]
  }
}

module "${key}" {
  source    = "./modules/gke"

  cluster   = local.clusters.gke["${key}"]
  forgerock = var.forgerock

  providers = {
    google     = google.${key}
    kubernetes = kubernetes.${key}
    helm       = helm.${key}
  }
  depends_on = [null_resource.clusters]
}

output "${key}" {
  value = format("\n\nGKE Cluster Configuration: %s\n%s\n", "${key}", module.${key}.cluster_info)
}
%{ endfor }

### EKS ####
%{ for key in keys(local.clusters.eks) }
provider "aws" {
  alias      = "${key}"

  region     = local.clusters.eks["${key}"].location["region"]
  access_key = local.clusters.eks["${key}"].auth["access_key"]
  secret_key = local.clusters.eks["${key}"].auth["secret_key"]
}

provider "kubernetes" {
  alias                  = "${key}"

  host                   = module.${key}.kube_config["host"]
  cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
  client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
  client_key             = module.${key}.kube_config["client_key"]
  token                  = module.${key}.kube_config["token"]
}

provider "helm" {
  alias = "${key}"

  kubernetes = {
    host                   = module.${key}.kube_config["host"]
    cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
    client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
    client_key             = module.${key}.kube_config["client_key"]
    token                  = module.${key}.kube_config["token"]
  }
}

module "${key}" {
  source    = "./modules/eks"

  cluster   = local.clusters.eks["${key}"]
  forgerock = var.forgerock

  providers = {
    aws        = aws.${key}
    kubernetes = kubernetes.${key}
    helm       = helm.${key}
  }
  depends_on = [null_resource.clusters]
}

output "${key}" {
  value = format("\n\nEKS Cluster Configuration: %s\n%s\n", "${key}", module.${key}.cluster_info)
}
%{ endfor }

### AKS ####
%{ for key in keys(local.clusters.aks) }
provider "azurerm" {
  alias = "${key}"

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  #skip_provider_registration = true
}

provider "kubernetes" {
  alias                  = "${key}"

  host                   = module.${key}.kube_config["host"]
  cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
  client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
  client_key             = base64decode(module.${key}.kube_config["client_key"])
  token                  = module.${key}.kube_config["token"]
}

provider "helm" {
  alias = "${key}"

  kubernetes = {
    host                   = module.${key}.kube_config["host"]
    cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
    client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
    client_key             = base64decode(module.${key}.kube_config["client_key"])
    token                  = module.${key}.kube_config["token"]
  }
}

module "${key}" {
  source    = "./modules/aks"

  cluster   = local.clusters.aks["${key}"]
  forgerock = var.forgerock

  providers = {
    azurerm    = azurerm.${key}
    kubernetes = kubernetes.${key}
    helm       = helm.${key}
  }
  depends_on = [null_resource.clusters]
}

output "${key}" {
  value = format("\n\nAKS Cluster Configuration: %s\n%s\n", "${key}", module.${key}.cluster_info)
}
%{ endfor }
EOF
      echo "clusters.tf created successfully."
    EOT
  }
  depends_on = [null_resource.backend]
}

