# /envs/pred/plt/poc/s3-state/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/s3-state"
}

dependency "iam-state" {
  config_path = "../iam-state"

  mock_outputs = {
    deploy_role_arn = "arn:aws:iam::000000000000:role/mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  bucket_name     = "poc-plt-terraform-state"
  versioning      = true
  deploy_role_arn = dependency.iam-state.outputs.deploy_role_arn
}
