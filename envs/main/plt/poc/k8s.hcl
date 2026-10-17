# /envs/main/plt/poc/k8s.hcl
# Included by stacks that talk to the Kubernetes API (platform, nginx).
# Authentication uses short-lived `aws eks get-token` exec credentials, so no
# token is ever stored in state or passed between stacks.

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

# Paths in an included file resolve relative to the including stack.
dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name           = "mock-cluster"
    cluster_endpoint       = "https://mock.eks.amazonaws.com"
    cluster_ca_certificate = "mock-ca"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

generate "k8s_provider" {
  path      = "provider_k8s.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}

provider "kubernetes" {
  host                   = ${jsonencode(dependency.eks.outputs.cluster_endpoint)}
  cluster_ca_certificate = ${jsonencode(dependency.eks.outputs.cluster_ca_certificate)}

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", ${jsonencode(dependency.eks.outputs.cluster_name)}, "--region", ${jsonencode(local.root.locals.region)}]
  }
}
EOF
}
