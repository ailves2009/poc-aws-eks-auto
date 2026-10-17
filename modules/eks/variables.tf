# /modules/eks/variables.tf

variable "region" {
  description = "AWS region of the cluster"
  type        = string
}

variable "account" {
  description = "AWS account ID of the cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "domain_name" {
  description = "Domain that external-dns is allowed to manage (domain filter)"
  type        = string
}

variable "zone_arn" {
  description = "ARN of the Route53 hosted zone external-dns may change"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the control plane ENIs and Auto Mode nodes"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint"
  type        = list(string)
  default     = []
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Retention for the control plane log group"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
