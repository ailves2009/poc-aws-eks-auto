# modules/dns/outputs.tf

output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = local.zone_id
}

output "zone_arn" {
  description = "ARN of the hosted zone"
  value       = local.zone_arn
}

output "name_servers" {
  description = "Name servers to delegate the zone to (NS record in the parent zone)"
  value       = local.name_servers
}
