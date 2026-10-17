# /envs/main/plt/poc/nginx/terragrunt.hcl

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "k8s" {
  path = find_in_parent_folders("k8s.hcl")
}

terraform {
  source = "../../../../../modules/nginx"
}

dependency "platform" {
  config_path = "../platform"

  mock_outputs = {
    ingress_class_name  = "alb"
    apps_node_pool_name = "apps"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

inputs = {
  namespace          = "nginx"
  hostname           = "nginx.${include.root.locals.domain_name}"
  ingress_class_name = dependency.platform.outputs.ingress_class_name
  node_pool          = dependency.platform.outputs.apps_node_pool_name

  hpa_min_replicas        = 2
  hpa_max_replicas        = 10
  hpa_average_utilization = 70

  cpu_request    = "100m"
  memory_request = "64Mi"
  cpu_limit      = "250m"
  memory_limit   = "128Mi"
}
