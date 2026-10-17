# /envs/main/plt/poc/dns/terragrunt.hcl
# After the first apply, add an NS record for the zone in the parent zone
# (parent_domain in root.hcl) using the name_servers output, otherwise ACM DNS
# validation never completes.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/dns"
}

inputs = {
  create_zone = true
  # external-dns owns the app records; allow the zone to go away on destroy.
  force_destroy = true
}
