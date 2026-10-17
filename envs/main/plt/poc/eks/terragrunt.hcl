# /envs/main/plt/poc/eks/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/eks"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002", "subnet-00000000000000003"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "dns" {
  config_path = "../dns"

  mock_outputs = {
    zone_id  = "Z0000000000000000000"
    zone_arn = "arn:aws:route53:::hostedzone/Z0000000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  kubernetes_version = "1.37"

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # Public API endpoint for the POC; restrict to your egress IP(s) in real use.
  endpoint_public_access       = true
  endpoint_public_access_cidrs = ["0.0.0.0/0"]

  cloudwatch_log_group_retention_in_days = 30

  zone_arn = dependency.dns.outputs.zone_arn
}
