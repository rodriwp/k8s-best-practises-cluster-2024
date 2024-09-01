provider "aws" {
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/automation-deployment-role"
  }
}

locals {
  name                             = "${var.account_name}-${var.region_code}-eks"
  region                           = var.region
  cluster_version                  = "1.30"
  coredns_addon_version            = "v1.11.1-eksbuild.11"
  kube-proxy_addon_version         = "v1.30.0-eksbuild.3"
  vpc-cni_addon_version            = "v1.18.3-eksbuild.2"
  aws-ebs-csi-driver_addon_version = "v1.34.0-eksbuild.1"
  tags = {
    env        = var.account_name
    managed-by = "terraform"
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
################################################################################
# VPC Module
################################################################################
data "aws_availability_zones" "available" {
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

resource "aws_eip" "nat" {
  tags = merge(
    local.tags,
    {
      Name = "kubernetes-vpc"
    },
  )
}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name                                 = "kubernetes-vpc"
  azs                                  = data.aws_availability_zones.available.names
  cidr                                 = var.vpc_cidr
  private_subnets                      = var.private_subnets
  public_subnets                       = var.public_subnets
  enable_flow_log                      = false
  create_flow_log_cloudwatch_log_group = false
  create_flow_log_cloudwatch_iam_role  = false
  flow_log_max_aggregation_interval    = 60
  enable_nat_gateway                   = true
  single_nat_gateway                   = true
  enable_dns_hostnames                 = true
  reuse_nat_ips                        = true
  external_nat_ip_ids                  = [aws_eip.nat.id]
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }
  tags = local.tags
}
################################################################################
# EKS Module
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_ip_family               = "ipv4"

  cluster_addons = {
    coredns = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
      addon_version               = local.coredns_addon_version
    }
    kube-proxy = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
      addon_version               = local.kube-proxy_addon_version
    }
    vpc-cni = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
      service_account_role_arn    = module.iam_eks_role_vpc_cni_irsa.iam_role_arn
      addon_version               = local.vpc-cni_addon_version
    }
    aws-ebs-csi-driver = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
      service_account_role_arn    = module.ebs_csi_irsa_role.iam_role_arn
      addon_version               = local.aws-ebs-csi-driver_addon_version
    }
  }

  cluster_tags = {
    env  = var.account_name
    Name = local.name
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  eks_managed_node_groups = {
    eks_cluster_node_group = {
      name = local.name

      ami_id                     = data.aws_ami.eks_default.image_id
      enable_bootstrap_user_data = true
      bootstrap_extra_args       = "--kubelet-extra-args '--container-log-max-files=4 --container-log-max-size=1Gi'"
      #Enable log rotation on worker node disk

      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
      capacity_type  = "ON_DEMAND"
      instance_types = var.instance_type

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.disk_size
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = false
          }
        }
      }
      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = false
      node_group_labels       = {}
      tags                    = local.tags
    }
  }

  access_entries = {
    # One access entry with a policy associated
    MompoAdminAccess = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${var.account_id}:role/MompoAdminAccess"

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  cluster_enabled_log_types = []
  tags                      = local.tags
}

################################################################################
# IAM Attachments
################################################################################
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSServicePolicy"
  role       = module.eks.cluster_iam_role_name
}

################################################################################
# IAM Service Accounts
################################################################################

module "iam_eks_role_vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name             = "${var.account_name}-${var.region_code}-eks-role-vpc-cni-irsa"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
  tags = local.tags
}

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name             = "${var.account_name}-${var.region_code}-eks-role-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}


module "node_termination_handler_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name                              = "${var.account_name}-${var.region_code}-eks-role-node-termination-handler"
  attach_node_termination_handler_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}

# For use for validating web-hooks in the ingress
resource "aws_security_group_rule" "webhook_admission_inbound" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
}

resource "aws_security_group_rule" "webhook_admission_outbound" {
  type                     = "egress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
}

data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${local.cluster_version}-v*"]
  }
}