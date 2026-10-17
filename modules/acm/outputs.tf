# /modules/acm/outputs.tf

output "wildcard_certificate_arn" {
  description = "ARN of the wildcard certificate for the domain"
  value       = aws_acm_certificate.wildcard.arn
}

output "cloudfront_certificate_arn" {
  description = "ARN of the CloudFront certificate in us-east-1"
  value       = var.create_cloudfront_certificate ? aws_acm_certificate.cloudfront_wildcard[0].arn : null
}

# Monitoring outputs
output "cloudwatch_alarm_arn" {
  description = "ARN of the CloudWatch alarm for certificate expiry"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.certificate_expiry[0].arn : null
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for certificate alerts"
  value       = var.create_sns_topic && length(var.alarm_email) > 0 ? aws_sns_topic.certificate_alerts[0].arn : null
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = var.enable_monitoring ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.region}#dashboards:name=${aws_cloudwatch_dashboard.certificate_monitoring[0].dashboard_name}" : null
}

output "critical_alarm_arn" {
  description = "ARN of the CloudWatch alarm for critical (7 days) certificate expiry"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.certificate_critical_expiry[0].arn : null
}
