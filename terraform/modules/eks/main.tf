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
  tags = merge(
    module.common.asset_labels,
    {
      cluster_name = local.cluster_name
      #cluster_name = terraform_data.cluster_name.output
    }
  )
}

#data "aws_eks_cluster" "cluster" {
#  name = try(module.eks.cluster_name, local.cluster_name)
#}

data "aws_eks_cluster_auth" "cluster" {
  name = try(module.eks.cluster_name, local.cluster_name)
}

data "aws_availability_zones" "available" {
  filter {
    name   = var.cluster.location["zones"] != null ? "zone-name" : "region-name"
    values = var.cluster.location["zones"] != null ? var.cluster.location["zones"] : [var.cluster.location["region"]]
  }
}

# Force update to data.aws_availability_zones.available with:
# terraform apply -target=module.<cluster_XX>.terraform_data.aws_availability_zones_available
resource "terraform_data" "aws_availability_zones_available" {
  triggers_replace = {
    names = join(",", data.aws_availability_zones.available.names)
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.4"

  name = "${local.cluster_name}-vpc"
  cidr = "10.0.0.0/16"
  azs = data.aws_availability_zones.available.names
  public_subnets = length(data.aws_availability_zones.available.names) > 2 ? ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19", "10.0.96.0/19"] : ["10.0.0.0/18", "10.0.64.0/18"]
  private_subnets = length(data.aws_availability_zones.available.names) > 2 ? ["10.0.128.0/19", "10.0.160.0/19", "10.0.192.0/19", "10.0.224.0/19"] : ["10.0.128.0/18", "10.0.192.0/18"]
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }

  #tags = module.common.asset_labels
  tags = local.tags
}

resource "aws_iam_policy" "ec2_describe" {
  name        = "${local.cluster_name}-ec2-describe"
  description = "${local.cluster_name} EC2 describe policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}

data "aws_ec2_instance_type" "pools" {
  for_each = var.cluster["node_pools"]

  instance_type = each.value.type
}

locals {
  taint_effects = {
    "noschedule" = "NO_SCHEDULE",
    "prefernoschedule" = "PREFER_NO_SCHEDULE",
    "noexecute" = "NO_EXECUTE"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.21"

  cluster_name                   = local.cluster_name
  cluster_version                = var.cluster.meta.kubernetes_version

  cluster_endpoint_public_access = true
  manage_aws_auth_configmap      = true

  create_iam_role                = true
  iam_role_name                  = local.cluster_name
  iam_role_use_name_prefix       = false
  iam_role_description           = "${local.cluster_name} EKS managed node group role"
  iam_role_tags                  = local.tags
  iam_role_additional_policies = {
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    EC2Describe                        = aws_iam_policy.ec2_describe.arn
  }

  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets
  #enable_irsa = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Allow cluster ingress access from the nodes."
      protocol                   = "-1"
      from_port                  = 0
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
    ingress_http = {
      description                = "Remote host to control plane"
      protocol                   = "tcp"
      from_port                  = 80
      to_port                    = 80
      type                       = "ingress"
      cidr_blocks                = ["0.0.0.0/0"]
    }
    ingress_https = {
      description                = "Remote host to control plane"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      cidr_blocks                = ["0.0.0.0/0"]
    }
  }

  node_security_group_additional_rules = {
    egress_self_all = {
      description = "Allow nodes to communicate with each other."
      protocol    = "-1"
      from_port   = 0
      to_port     = 65535
      type        = "egress"
      self        = true
    }
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 65535
      type        = "ingress"
      self        = true
    }
    ingress_cluster_all = {
      description = "Allow worker pods to receive communication from the cluster control plane."
      protocol    = "-1"
      from_port   = 0
      to_port     = 65535
      type        = "ingress"
      source_cluster_security_group = true
    }
  }

  eks_managed_node_group_defaults = {
    platform = "bottlerocket"
    ami_type = "BOTTLEROCKET_x86_64"

    use_custom_launch_template            = false
    attach_cluster_primary_security_group = true

    iam_role_additional_policies = {
      AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      EC2Describe                        = aws_iam_policy.ec2_describe.arn
    }
  }

  eks_managed_node_groups = {
    for pool_name, pool in var.cluster["node_pools"]:
      pool_name => {
        name = pool_name
        #use_custom_launch_template = false

        instance_types = [pool.type]
        subnet_ids = lookup(pool.meta, "zones", null) == null ? module.vpc.private_subnets : [
          for zone in lookup(pool.meta, "zones", null):
            module.vpc.private_subnets[index(data.aws_availability_zones.available.names, zone)]
        ]
        ami_type = contains(data.aws_ec2_instance_type.pools[pool_name].supported_architectures, "arm64") ? "BOTTLEROCKET_ARM_64" : "BOTTLEROCKET_x86_64"

        disk_size = lookup(pool, "disk_size_gb", null) == null ? 50 : lookup(pool, "disk_size_gb", null)
        desired_size = pool.initial_count
        min_size = pool.min_count
        max_size = pool.max_count

        bootstrap_extra_args = <<-EOF
          [settings.kernel]
          lockdown = "integrity"
        EOF

        update_config = {
          max_unavailable_percentage = 33
        }

        labels = (lookup(pool, "labels", null) == null ? module.common.asset_labels : merge(module.common.asset_labels, lookup(pool, "labels", null)))
        taints = lookup(pool, "taints", null) == null ? [] : [
          for taint in (lookup(pool, "taints", null) == null ? [] : lookup(pool, "taints", null)):
            {
              key    = taint["key"]
              value  = taint["value"]
              effect = lookup(local.taint_effects, lower(taint["effect"]), taint["effect"])
            }
        ]

        tags = merge(
          local.tags,
          {
            "k8s.io/cluster-autoscaler/enabled" = "true"
            "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
            "k8s.io/cluster-autoscaler/node-template/label/node.kubernetes.io/instance-type" = pool.type
            "k8s.io/cluster-autoscaler/node-template/label/kubernetes.io/arch" = contains(data.aws_ec2_instance_type.pools[pool_name].supported_architectures, "arm64") ? "arm64" : "amd64"
          }
        )
      }
  }

  tags = module.common.asset_labels
}

