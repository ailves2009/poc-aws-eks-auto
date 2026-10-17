# modules/dns/main.tf
#
# Public hosted zone for the POC subdomain. Create it here (default) and
# delegate it from the parent zone with the name_servers output, or set
# create_zone = false to look up a zone that already exists in the account.

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name          = var.domain_name
  comment       = var.comment
  force_destroy = var.force_destroy
  tags          = var.tags
}

data "aws_route53_zone" "this" {
  count = var.create_zone ? 0 : 1

  name         = var.domain_name
  private_zone = false
}

locals {
  zone_id      = one(concat(aws_route53_zone.this[*].zone_id, data.aws_route53_zone.this[*].zone_id))
  zone_arn     = one(concat(aws_route53_zone.this[*].arn, data.aws_route53_zone.this[*].arn))
  name_servers = one(concat(aws_route53_zone.this[*].name_servers, data.aws_route53_zone.this[*].name_servers))
}
