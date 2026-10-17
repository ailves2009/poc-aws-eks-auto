# /modules/s3-state/outputs.tf

output "s3_bucket_arn" {
  description = "ARN of the Terraform state bucket"
  value       = aws_s3_bucket.state_s3.arn
}

output "region" {
  value = data.aws_region.current.region
}

output "account" {
  value = data.aws_caller_identity.current.account_id
}

output "kms_key_arn" {
  description = "KMS key that encrypts the state objects"
  value       = aws_kms_key.this.arn
}
