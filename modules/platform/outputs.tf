# /modules/platform/outputs.tf

output "ingress_class_name" {
  description = "IngressClass backed by the Auto Mode ALB controller"
  value       = kubernetes_ingress_class_v1.alb.metadata[0].name
}

output "apps_node_pool_name" {
  description = "NodePool name; pods select it via the workload-tier node label"
  value       = var.apps_node_pool.name
}
