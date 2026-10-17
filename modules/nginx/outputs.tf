# modules/nginx/outputs.tf

output "url" {
  description = "Public URL of the demo app"
  value       = "https://${var.hostname}"
}

output "alb_hostname" {
  description = "Hostname of the ALB created by EKS Auto Mode"
  value       = try(kubernetes_ingress_v1.nginx.status[0].load_balancer[0].ingress[0].hostname, null)
}
