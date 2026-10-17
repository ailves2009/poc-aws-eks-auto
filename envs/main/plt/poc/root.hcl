# /envs/main/plt/poc/root.hcl
# Shared settings for every stack under envs/main/plt/poc.

locals {
  region       = "eu-west-3"
  account      = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals.aws_account_id
  env          = "plt"
  client       = "poc"
  cluster_name = "nyd-plt-eks"

  # The only place the domain is set. The POC gets its own delegated zone
  # (<subdomain>.<parent_domain>); every hostname is derived from domain_name.
  parent_domain = "ailves2009.com"
  subdomain     = "nyd-plt"
  domain_name   = "${local.subdomain}.${local.parent_domain}"
  state_bucket  = "poc-plt-terraform-state"

  tags = {
    Env     = local.env
    Client  = local.client
    Managed = "terraform"
    Account = local.account
    Project = "poc-aws-eks-auto"
  }
}

# One backend definition for all stacks; the state key mirrors the stack path
# (e.g. "eks/terraform.tfstate"), so stacks never collide.
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket       = local.state_bucket
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    use_lockfile = true
  }
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region              = "${local.region}"
  allowed_account_ids = ["${local.account}"]

  default_tags {
    tags = ${jsonencode(local.tags)}
  }
}

provider "aws" {
  alias               = "us_east_1"
  region              = "us-east-1"
  allowed_account_ids = ["${local.account}"]

  default_tags {
    tags = ${jsonencode(local.tags)}
  }
}
EOF
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
EOF
}

inputs = {
  region       = local.region
  account      = local.account
  env          = local.env
  client       = local.client
  domain_name  = local.domain_name
  cluster_name = local.cluster_name
  tags         = local.tags
}
