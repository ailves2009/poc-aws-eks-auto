# /modules/acm/variables.tf

variable "domain_name" {
  description = "Domain name for the ACM certificate"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone for the DNS validation records"
  type        = string
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring for certificate expiry"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for certificate expiry alerts (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# Email configuration for certificate alerts
variable "alarm_email" {
  description = "List of email addresses to receive certificate expiry alerts"
  type        = list(string)
  default     = []
}

variable "create_sns_topic" {
  description = "Whether to create a new SNS topic for alerts or use existing one"
  type        = bool
  default     = true
}

variable "sns_topic_name" {
  description = "Name for the SNS topic (only used if create_sns_topic is true)"
  type        = string
  default     = null
}

variable "create_cloudfront_certificate" {
  description = "Whether to create an additional certificate in us-east-1 for CloudFront"
  type        = bool
  default     = false
}
