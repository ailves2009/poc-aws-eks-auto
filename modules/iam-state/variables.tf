# /modules/iam-state/variables.tf

variable "cicd_role_name" {
  description = "Name of the CI/CD IAM role"
  type        = string
}

variable "cicd_account_arn" {
  description = "IAM principal allowed to assume the CI/CD role"
  type        = string
}

variable "account" {
  description = "Target AWS account ID"
  type        = string
}

variable "region" {
  description = "AWS region the role may deploy to"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name; also the name prefix of IAM roles/policies the role may manage"
  type        = string
}

variable "s3_terraform_state" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "project_tag" {
  description = "Value of the Project tag on KMS keys the role may manage"
  type        = string
  default     = "poc-aws-eks-auto"
}

variable "tags" {
  description = "Tags for the IAM role"
  type        = map(string)
  default     = {}
}
