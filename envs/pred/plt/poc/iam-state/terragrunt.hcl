# /envs/pred/plt/poc/iam-state/terragrunt.hcl

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../../modules/iam-state"
}

inputs = {
  cicd_role_name     = "cicd-role"
  cicd_account_arn   = "arn:aws:iam::${include.root.locals.account}:user/terraform"
  cluster_name       = "nyd-plt-eks"
  s3_terraform_state = "poc-plt-terraform-state"
}
