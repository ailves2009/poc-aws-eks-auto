# modules/acm/monitoring.tf
# Expiry monitoring for the ACM certificate (ACM auto-renews DNS-validated
# certificates; the alarms catch a renewal that silently fails, e.g. after the
# validation CNAME is removed).

# Local variable for determining SNS topic ARN
locals {
  sns_topic_arn = var.create_sns_topic && length(var.alarm_email) > 0 ? aws_sns_topic.certificate_alerts[0].arn : var.sns_topic_arn
}

# SNS Topic for certificate alerts
resource "aws_sns_topic" "certificate_alerts" {
  count = var.create_sns_topic && length(var.alarm_email) > 0 ? 1 : 0
  name  = var.sns_topic_name != null ? var.sns_topic_name : "acm-certificate-alerts-${replace(var.domain_name, ".", "-")}"
  tags = merge(var.tags, {
    Name   = "ACM Certificate Alerts"
    Domain = var.domain_name
  })
}

# Email subscriptions for SNS Topic
resource "aws_sns_topic_subscription" "certificate_email_alerts" {
  for_each  = var.create_sns_topic && length(var.alarm_email) > 0 ? toset(var.alarm_email) : []
  topic_arn = aws_sns_topic.certificate_alerts[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# CloudWatch Alarm for monitoring certificate expiry
resource "aws_cloudwatch_metric_alarm" "certificate_expiry" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "acm-certificate-expiry-${replace(var.domain_name, ".", "-")}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = "86400" # 24 hours
  statistic           = "Minimum"
  threshold           = "30" # Warning 30 days before expiry
  alarm_description   = "SSL Certificate expires in less than 30 days"
  alarm_actions       = local.sns_topic_arn != null ? [local.sns_topic_arn] : []
  ok_actions          = local.sns_topic_arn != null ? [local.sns_topic_arn] : []
  treat_missing_data  = "breaching"

  dimensions = {
    CertificateArn = aws_acm_certificate.wildcard.arn
  }

  tags = merge(var.tags, {
    Name   = "ACM Certificate Expiry Monitor"
    Domain = var.domain_name
  })
}

# CloudWatch Dashboard for visualizing certificate status
resource "aws_cloudwatch_dashboard" "certificate_monitoring" {
  count = var.enable_monitoring ? 1 : 0

  dashboard_name = "acm-certificates-${replace(var.domain_name, ".", "-")}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CertificateManager", "DaysToExpiry", "CertificateArn", aws_acm_certificate.wildcard.arn]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.region
          title   = "SSL Certificate Days to Expiry"
          period  = 300
          stat    = "Minimum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 6
        height = 4

        properties = {
          metrics = [
            ["AWS/CertificateManager", "DaysToExpiry", "CertificateArn", aws_acm_certificate.wildcard.arn]
          ]
          view   = "singleValue"
          region = data.aws_region.current.region
          title  = "Current Days to Expiry"
          period = 300
          stat   = "Minimum"
        }
      }
    ]
  })
}

# Additional alarm for critical warning (7 days)
resource "aws_cloudwatch_metric_alarm" "certificate_critical_expiry" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "acm-certificate-critical-expiry-${replace(var.domain_name, ".", "-")}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = "86400" # 24 hours
  statistic           = "Minimum"
  threshold           = "7" # Critical warning 7 days before expiry
  alarm_description   = "CRITICAL: SSL Certificate expires in less than 7 days!"
  alarm_actions       = local.sns_topic_arn != null ? [local.sns_topic_arn] : []
  ok_actions          = local.sns_topic_arn != null ? [local.sns_topic_arn] : []
  treat_missing_data  = "breaching"

  dimensions = {
    CertificateArn = aws_acm_certificate.wildcard.arn
  }

  tags = merge(var.tags, {
    Name     = "ACM Certificate Critical Expiry Monitor"
    Domain   = var.domain_name
    Severity = "Critical"
  })
}

data "aws_region" "current" {}
