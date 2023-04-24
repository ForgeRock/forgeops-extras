# outputs.tf - cluster module outputs

locals {
  kube_config = {
    "config_path"            = "~/.kube/config-tf.eks.${var.cluster.location.region}.${local.cluster_name}"
    "host"                   = tostring(try(module.eks.cluster_endpoint, null)),
    "cluster_ca_certificate" = tostring(try(module.eks.cluster_certificate_authority_data, null)),
    "client_certificate"     = "",
    "client_key"             = "",
    "token"                  = data.aws_eks_cluster_auth.cluster.token
  }
  kube_config_yaml = yamlencode({
        apiVersion = "v1"
        kind = "Config"
        current-context = tostring(try(module.eks.cluster_name, null))
        contexts = [{
          name = tostring(try(module.eks.cluster_name, null))
          context = {
            cluster = tostring(try(module.eks.cluster_name, null))
            user = tostring(try(module.eks.cluster_name, null))
          }
        }]
        clusters = [{
          name = tostring(try(module.eks.cluster_name, null))
          cluster = {
            certificate-authority-data = local.kube_config["cluster_ca_certificate"]
            server = local.kube_config["host"]
          }
        }]
        users = [{
          name = tostring(try(module.eks.cluster_name, null))
          user = {
            token = local.kube_config["token"]
          }
        }]
    })
}

output "kube_config" {
  value = local.kube_config
}

resource "local_file" "kube_config" {
  filename             = pathexpand(local.kube_config["config_path"])
  file_permission      = "0600"
  directory_permission = "0775"
  content              = <<-EOF
  apiVersion: v1
  kind: Config
  preferences:
    colors: true
  current-context: ${tostring(try(module.eks.cluster_name, null))}
  contexts:
  - context:
      cluster: ${tostring(try(module.eks.cluster_name, null))}
      namespace: default
      user: ${tostring(try(module.eks.cluster_name, null))}
    name: ${tostring(try(module.eks.cluster_name, null))}
  clusters:
  - cluster:
      server: ${local.kube_config["host"]}
      certificate-authority-data: ${local.kube_config["cluster_ca_certificate"]}
    name: ${tostring(try(module.eks.cluster_name, null))}
  users:
  - name: ${tostring(try(module.eks.cluster_name, null))}
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1beta1
        command: aws
        args:
        - eks
        - get-token
        - --cluster-name
        - ${tostring(try(module.eks.cluster_name, null))}
        env: null
  EOF
}

module "common-output" {
  source = "../common-output"

  cluster       = merge(var.cluster, {type = "EKS", meta = {cluster_name = local.cluster_name, kubernetes_version = tostring(try(module.eks.cluster_platform_version, null))}})
  kube_config   = local.kube_config
  helm_metadata = module.helm.metadata

  depends_on = [module.helm]
}

output "cluster_info" {
  value = module.common-output.cluster_info
}

