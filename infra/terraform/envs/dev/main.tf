locals {
  env = "dev"
}

#================================================================
# VPC for the EKS Cluster
#================================================================
module "vpc" {
  source              = "../../modules/vpc"
  name                = "app-${local.env}"
  cidr_block          = "10.0.0.0/16"
  azs                 = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnet_count = 3
  private_subnet_count = 3

  tags = {
    Environment = local.env
    Project     = "sample-app"
  }
}

#================================================================
# ECR (Container Registry)
#================================================================
module "ecr" {
  source       = "../../modules/ecr"
  repositories = ["g5_slabai_payment", "g5_slabai_project", "g5_slabai_user", "g5_slabai_frontend"]
  tags         = { Environment = local.env }
}

#================================================================
# EKS Cluster (Development Configuration)
#================================================================
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "app-${local.env}"
  vpc_id          = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.public_subnet_ids
  # Development-focused node group: smaller, single node
  # eks_managed_node_groups = {
  #   dev-workers = {
  #     desired_size   = 1
  #     max_size       = 2
  #     min_size       = 1
  #     instance_types = ["t3.small"] # t3.small is cost-effective for dev
  #     capacity_type  = "ON_DEMAND"
  #   }

  #   spot = {
  #     desired_size = 1
  #     max_size     = 1
  #     min_size     = 0
  #     instance_types = ["t3.small"]
  #     capacity_type  = "SPOT"
  #   }
  # }
}

#================================================================
# IAM Role for External Secrets (IRSA)
#================================================================
# module "iam_irsa" {
#   source = "../../modules/iam_irsa"

#   cluster_name             = module.eks.name
#   oidc_provider_url        = module.eks.oidc_provider_url
#   oidc_provider_thumbprint = module.eks.oidc_provider_thumbprint
#   aws_region               = var.aws_region

#   # Details for the External Secrets service account
#   external_secrets_namespace = "external-secrets"
#   external_secrets_sa        = "external-secrets-sa"
  
#   # Specify the secrets it can access
#   external_secrets_resources = [
#     "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:/app-dev/*"
#   ]

#   tags = { Environment = local.env }
# }

# data "aws_caller_identity" "current" {}
