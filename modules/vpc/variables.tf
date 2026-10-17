# /modules/vpc/variables.tf

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Create one NAT Gateway per Availability Zone"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_flow_log" {
  description = "Send VPC Flow Logs to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_in_days" {
  description = "Retention for the VPC Flow Logs log group"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
