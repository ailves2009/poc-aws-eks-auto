# /envs/main/plt/poc/vpc/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/vpc"
}

inputs = {
  vpc_name       = "nyd-plt-eks"
  vpc_cidr_block = "10.0.0.0/16"

  enable_nat_gateway   = true
  single_nat_gateway   = true # POC cost trade-off: one NAT for all AZs
  enable_dns_hostnames = true

  enable_flow_log                   = true
  cloudwatch_logs_retention_in_days = 30
}
