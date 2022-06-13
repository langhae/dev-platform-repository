################################################################################
# Backend terraform Cloud
################################################################################

terraform {
  backend "remote" {
    organization = "langhae"

    workspaces {
      name = "eks-cluster-all"
    }
  }
}

################################################################################
# Local variable
################################################################################

locals {
  cluster_name      = "multi05-eks-terraform"
  cluster_version   = "1.22"
  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  region            = "ap-southeast-2"

  vpc_name        = "multi05-vpc-terrafotm"
  vpc_cidr        = "10.0.0.0/16"
  service_cidr    = "172.20.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  public_subnets_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnets_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }

  control_plane_security_groups_tags = {
    Name                                          = "multi05-eks-controle-plane-security-group"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }

  node_groups_security_groups_tags = {
    Name                                          = "multi05-eks-node-security-group"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }

  tags = {
    Example    = local.cluster_name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# data
################################################################################

data "aws_security_groups" "all" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${local.cluster_version}-v*"]
  }
}