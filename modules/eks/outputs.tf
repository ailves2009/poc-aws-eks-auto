# /modules/eks/outputs.tf

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (PEM)"
  value       = base64decode(module.eks.cluster_certificate_authority_data)
}

output "node_iam_role_name" {
  description = "IAM role used by Auto Mode nodes"
  value       = module.eks.node_iam_role_name
}

output "external_dns_role_arn" {
  description = "IAM role assumed by external-dns via Pod Identity"
  value       = aws_iam_role.external_dns.arn
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
