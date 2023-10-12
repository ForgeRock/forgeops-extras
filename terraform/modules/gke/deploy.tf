# deploy.tf - deploy components into cluster

locals {
  # external-secrets
  deploy_external_secrets          = contains(keys(var.cluster.helm), "external-secrets") ? tobool(lookup(var.cluster.helm["external-secrets"], "deploy", true)) : true
  create_external_secrets_acct     = local.deploy_external_secrets && contains(keys(var.cluster.helm), "external-secrets") ? tobool(lookup(var.cluster.helm["external-secrets"], "create_service_account", false)) : false
  external_secrets_service_account = local.deploy_external_secrets && local.create_external_secrets_acct ? google_service_account.external_secrets[0].email : local.deploy_external_secrets && local.create_external_secrets_acct == false ? lookup(var.cluster.helm["external-secrets"], "service_account_email", "") : ""
  external_secrets_values = local.deploy_external_secrets ? yamlencode({
    serviceAccount = {
      annotations = {
        "iam.gke.io/gcp-service-account" = local.external_secrets_service_account
      }
    }
  }) : ""

  # external-dns
  deploy_external_dns          = contains(keys(var.cluster.helm), "external-dns") ? tobool(lookup(var.cluster.helm["external-dns"], "deploy", true)) : true
  create_external_dns_acct     = local.deploy_external_dns && contains(keys(var.cluster.helm), "external-dns") ? tobool(lookup(var.cluster.helm["external-dns"], "create_service_account", false)) : false
  external_dns_service_account = local.deploy_external_dns && local.create_external_dns_acct ? google_service_account.external_dns[0].email : local.deploy_external_dns && local.create_external_dns_acct == false ? lookup(var.cluster.helm["external-dns"], "service_account", "") : ""
  external_dns_values = local.deploy_external_dns ? yamlencode({
    provider = "google"
    google = {
      project = local.project
    }
    txtOwnerId = "${local.cluster_name}.${var.cluster.location.region}"
    serviceAccount = {
      annotations = {
        "iam.gke.io/gcp-service-account" = local.external_dns_service_account
      }
    }
  }) : ""
}

resource "google_service_account" "external_secrets" {
  count        = local.deploy_external_secrets && local.create_external_secrets_acct ? 1 : 0
  account_id   = replace(substr("${local.cluster_name}-external-secrets", 0, 30), "/[^a-z0-9]$/", "")
  display_name = substr("External Secrets service account for k8s cluster: ${local.cluster_name}", 0, 100)
}

resource "google_project_iam_member" "external_secrets_admin" {
  count   = local.deploy_external_secrets && local.create_external_secrets_acct ? 1 : 0
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${google_service_account.external_secrets[0].email}"
  project = local.project
}

resource "google_project_iam_member" "external_secrets_service_account_token_creator" {
  count   = local.deploy_external_secrets && local.create_external_secrets_acct ? 1 : 0
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.external_secrets[0].email}"
  project = local.project
}

resource "google_service_account_iam_member" "external_secrets_workload_identity_user" {
  count              = local.deploy_external_secrets && local.create_external_secrets_acct ? 1 : 0
  service_account_id = google_service_account.external_secrets[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${module.gke.identity_namespace}[external-secrets/external-secrets]"
}

resource "google_service_account" "external_dns" {
  count        = local.deploy_external_dns && local.create_external_dns_acct ? 1 : 0
  account_id   = replace(substr("${local.cluster_name}-external-dns", 0, 30), "/[^a-z0-9]$/", "")
  display_name = substr("ExternalDNS service account for k8s cluster: ${local.cluster_name}", 0, 100)
  #project = lookup(var.cluster.meta, "dns_zone_project", null)
}

resource "google_project_iam_member" "external_dns_admin" {
  count   = local.deploy_external_dns && local.create_external_dns_acct ? 1 : 0
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.external_dns[0].email}"
  project = local.project
  #project = lookup(var.cluster.meta, "dns_zone_project", local.project)
}

#resource "google_service_account_key" "external_dns" {
#  count              = local.deploy_external_dns && local.create_external_dns_acct ? 1 : 0
#  service_account_id = google_service_account.external_dns[0].name
#}

resource "google_service_account_iam_member" "external_dns_workload_identity_user" {
  count              = local.deploy_external_dns && local.create_external_dns_acct ? 1 : 0
  service_account_id = google_service_account.external_dns[0].name
  role               = "roles/iam.workloadIdentityUser"
  #  member = "serviceAccount:${local.project}.svc.id.goog[${module.helm.metadata["external-dns"]["namespace"]}/external-dns]"
  #member = "serviceAccount:${local.project}.svc.id.goog[external-dns/external-dns]"
  member = "serviceAccount:${module.gke.identity_namespace}[external-dns/external-dns]"
}

resource "google_compute_address" "ingress" {
  name         = "${local.cluster_name}-${var.cluster.location.region}"
  address_type = "EXTERNAL"

  depends_on = [module.gke]
}

locals {
  deploy_identity_platform = contains(keys(var.cluster.helm), "identity-platform") ? tobool(lookup(var.cluster.helm["identity-platform"], "deploy", false)) : false
}

module "helm" {
  source = "../helm"

  chart_configs = var.cluster.helm

  charts = {
    "external-secrets" = {
      "values" = local.external_secrets_values
    },
    "external-dns" = {
      "values" = local.external_dns_values
    },
    "ingress-nginx" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      controller:
        service:
          loadBalancerIP: ${google_compute_address.ingress.address}
      EOF
    },
    "haproxy-ingress" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      controller:
        service:
          loadBalancerIP: ${google_compute_address.ingress.address}
      EOF
    },
    "cert-manager" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    #"trust-manager" = {
    #  "values" = <<-EOF
    #  # Values from terraform GKE module
    #  EOF
    #},
    "kube-prometheus-stack" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    "elasticsearch" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    "logstash" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    "kibana" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      EOF
    },
    "raw-k8s-resources" = {
      "values" = <<-EOF
      # Values from terraform GKE module
      resources:
       #- apiVersion: external-secrets.io/v1beta1
       #   kind: ClusterSecretStore
       #   metadata:
       #     name: default-secrets-store
       #   spec:
       #     provider:
       #       gcpsm:
       #         projectID: ${local.project}
       #         auth:
       #           workloadIdentity:
       #             clusterLocation: ${var.cluster.location.region}
       #             clusterName: ${local.cluster_name}
       #             clusterProjectID: ${local.project}
       #             serviceAccountRef:
       #               name: external-secrets
       #               namespace: external-secrets
${local.deploy_identity_platform == false ? <<EOF
        - apiVersion: storage.k8s.io/v1
          kind: StorageClass
          metadata:
            name: fast
            #annotations:
            #  "storageclass.kubernetes.io/is-default-class": "true"
          parameters:
            type: pd-ssd
          provisioner: pd.csi.storage.gke.io
          reclaimPolicy: Delete
          volumeBindingMode: WaitForFirstConsumer
        - apiVersion: snapshot.storage.k8s.io/v1
          kind: VolumeSnapshotClass
          metadata:
            name: ds-snapshot-class
          driver: pd.csi.storage.gke.io
          deletionPolicy: Delete
EOF
      : ""
    }
      EOF
  },
  "secret-agent" = {
    "values" = <<-EOF
      # Values from terraform GKE module
      EOF
  },
  "identity-platform" = {
    "values" = <<-EOF
      # Values from terraform GKE module
      platform:
        ingress:
          hosts:
            - identity-platform.${google_compute_address.ingress.address}.nip.io
        storage:
          storage_class:
            name: fast
            create:
              provisioner: pd.csi.storage.gke.io
              parameters:
                type: pd-ssd
          volume_snapshot_class:
            name: ds-snapshot-class
            create:
              driver: pd.csi.storage.gke.io
      EOF
  }
}

depends_on = [module.gke, google_compute_address.ingress]
}
