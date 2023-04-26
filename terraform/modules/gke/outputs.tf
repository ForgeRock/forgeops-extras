# outputs.tf - cluster module outputs

locals {
  kube_config = {
    "config_path" = "~/.kube/config-tf.gke.${var.cluster.location.region}.${local.cluster_name}"
    "host" = "https://${tostring(try(module.gke.endpoint, null))}",
    "cluster_ca_certificate" = tostring(try(module.gke.ca_certificate, null)),
    "client_certificate" = "",
    "client_key" = "",
    "token" = data.google_client_config.default.access_token
  }
}

output "kube_config" {
  value = local.kube_config
}

resource "local_file" "kube_config" {
  filename = pathexpand(local.kube_config["config_path"])
  file_permission = "0600"
  directory_permission = "0775"
  content  = <<-EOF
  apiVersion: v1
  kind: Config
  preferences:
    colors: true
  current-context: ${tostring(try(module.gke.name, null))}
  contexts:
  - context:
      cluster: ${tostring(try(module.gke.name, null))}
      namespace: default
      user: ${tostring(try(module.gke.name, null))}
    name: ${module.gke.name}
  clusters:
  - cluster:
      server: ${local.kube_config["host"]}
      certificate-authority-data: ${local.kube_config["cluster_ca_certificate"]}
    name: ${tostring(try(module.gke.name, null))}
  users:
  - name: ${tostring(try(module.gke.name, null))}
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1beta1
        command: gke-gcloud-auth-plugin
        provideClusterInfo: true
  EOF
}

module "common-output" {
  source = "../common-output"

  cluster      = merge(var.cluster, {type = "GKE", meta = {cluster_name = local.cluster_name, kubernetes_version = tostring(try(module.gke.master_version, null))}})
  kube_config  = local.kube_config
  helm_metadata = module.helm.metadata

  depends_on = [module.helm]
}

output "cluster_info" {
  value = module.common-output.cluster_info
}

