# Criação do cluster EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access = false

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      min_size     = var.node_group_size
      max_size     = var.node_group_size
      desired_size = var.node_group_size

      instance_types = [var.instance_type]

      tags = {
        Name        = "${var.cluster_name}-node-group"
        Environment = var.Environment
        Terraform   = "true"
      }
    }
  }

  tags = {
    Environment = var.Environment
    Terraform   = "true"
  }
}
