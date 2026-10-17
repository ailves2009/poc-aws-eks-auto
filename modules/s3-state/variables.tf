# /modules/s3-state/variables.tf

variable "bucket_name" {
  description = "S3 bucket name for storing Terraform state"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "deploy_role_arn" {
  description = "The ARN of the CICD deployment role"
  type        = string
}

variable "versioning" {
  description = "Enable versioning for the S3 bucket (keep enabled for Terraform state)"
  type        = bool
  default     = true
}

variable "noncurrent_version_retention_days" {
  description = "Days to keep previous state versions"
  type        = number
  default     = 90
}
