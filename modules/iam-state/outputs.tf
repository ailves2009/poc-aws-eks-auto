# /modules/iam-state/outputs.tf

output "deploy_role_arn" {
  description = "ARN cicd-role"
  value       = aws_iam_role.deploy_assume_role.arn
}
