module "eks" {
  # source  = "terraform-aws-modules/eks/aws"
  # It's a best practice to pin to a major version to avoid unexpected breaking changes
  # version = ">= 21.0.0"

  # # --- CORRECTED ARGUMENTS ---
  # name               = var.cluster_name       # Renamed from cluster_name
  # kubernetes_version = var.cluster_version    # Renamed from cluster_version
  # # 'manage_aws_auth_configmap' is removed. The module now handles auth via access entries.

  # vpc_id                  = var.vpc_id
  # subnet_ids              = var.private_subnet_ids # Note: This is for both control plane and nodes by default

  # eks_managed_node_groups = var.eks_managed_node_groups
  
  # # This new setting is recommended. It automatically gives the IAM identity
  # # that creates the cluster admin permissions, which is often what you want.
  # enable_cluster_creator_admin_permissions = true

  # tags = merge(var.tags, { Environment = var.environment })
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  
  # Disable IRSA since no IAM permissions
  enable_irsa = false
  
  # Use existing KMS key instead of creating a new one
  create_kms_key = false
  cluster_encryption_config = {
    resources = ["secrets"]
    provider_key_arn = "arn:aws:kms:us-west-2:975050024946:key/1140c8f6-0ca9-41b7-80ba-af9427dad981"
  }
  
  vpc_id = var.vpc_id
  subnet_ids = var.private_subnet_ids

  eks_managed_node_group_defaults = {
      instance_types = ["t3.small"]
  }

  eks_managed_node_groups = {
    one = {
      name = "g5-node-group-1"

      # Instance sizing
      min_size     = 2
      max_size     = 4
      desired_size = 3

      # Instance type
      instance_types = ["t3.small"]
      capacity_type  = "SPOT"
      # Optional: Add custom tags to nodes
      tags = {
        "NodeType" = "general-purpose",
        "NodeGroup" = "one"
      }
    },
    two = {
      name = "g5-node-group-2"

      # Instance sizing
      min_size     = 2
      max_size     = 4
      desired_size = 3

      # Instance type
      instance_types = ["t3.small"]
      capacity_type  = "SPOT"
      # Optional: Add custom tags to nodes
      tags = {
        "NodeType" = "general-purpose"
        "NodeGroup" = "two"
      }
    }
  }

  cluster_addons = {
    # aws-ebs-csi-driver = {
    #   service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    # }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
# data "aws_iam_policy" "ebs_csi_policy" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }

# module "irsa-ebs-csi" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version = "5.39.0"

#   create_role                   = true
#   role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
#   provider_url                  = module.eks.oidc_provider
#   role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
# }