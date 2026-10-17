# /envs/pred/plt/poc/root.hcl
# Bootstrap environment: creates the CI/CD role and the state bucket that
# envs/main uses. State stays local here (chicken-and-egg); *.tfstate is
# git-ignored, so keep a copy of it somewhere safe.

locals {
  region  = "eu-west-3"
  account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals.aws_account_id

  tags = {
    Env     = "pred"
    Client  = "poc"
    Managed = "terraform"
    Account = local.account
    Project = "poc-aws-eks-auto"
  }
}

generate "providers" {
  path      = "providers.tf"
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

provider "aws" {
  region              = "${local.region}"
  allowed_account_ids = ["${local.account}"]

  default_tags {
    tags = ${jsonencode(local.tags)}
  }
}
EOF
}

inputs = {
  region  = local.region
  account = local.account
  tags    = local.tags
}
