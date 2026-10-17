# /modules/vpc/main.tf
# VPC with private subnets for EKS Auto Mode nodes and public subnets for ALBs.

data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = var.vpc_name
  cidr = var.vpc_cidr_block
  azs  = local.azs

  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr_block, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr_block, 8, k + 48)]

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  enable_dns_hostnames   = var.enable_dns_hostnames

  enable_flow_log                                 = var.enable_flow_log
  create_flow_log_cloudwatch_log_group            = var.enable_flow_log
  create_flow_log_cloudwatch_iam_role             = var.enable_flow_log
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = var.cloudwatch_logs_retention_in_days

  # Subnet discovery tags used by the EKS Auto Mode load balancer controller.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.tags
}
