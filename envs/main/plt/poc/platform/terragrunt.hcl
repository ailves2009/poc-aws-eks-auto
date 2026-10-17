# /envs/main/plt/poc/platform/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "k8s" {
  path = find_in_parent_folders("k8s.hcl")
}

terraform {
  source = "../../../../../modules/platform"
}

dependency "acm" {
  config_path = "../acm"

  mock_outputs = {
    wildcard_certificate_arn = "arn:aws:acm:eu-west-3:000000000000:certificate/mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

inputs = {
  certificate_arn = dependency.acm.outputs.wildcard_certificate_arn

  apps_node_pool = {
    name                    = "apps"
    architectures           = ["arm64"]             # Graviton
    capacity_types          = ["spot", "on-demand"] # Spot preferred, On-Demand fallback
    instance_categories     = ["c", "m"]
    min_instance_generation = 6
    cpu_limit               = 16
    memory_limit            = "64Gi"
  }
}
