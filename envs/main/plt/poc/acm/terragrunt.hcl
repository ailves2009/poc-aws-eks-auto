# /envs/main/plt/poc/acm/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/acm"
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
  zone_id = dependency.dns.outputs.zone_id

  enable_monitoring = true
  # Add real addresses to get e-mail notifications (each must confirm the SNS
  # subscription). With an empty list the alarms are created without actions.
  alarm_email    = []
  sns_topic_name = "acm-certificates"
}
