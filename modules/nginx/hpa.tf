# modules/nginx/hpa.tf
# CPU metrics come from the metrics-server EKS community add-on.

resource "kubernetes_horizontal_pod_autoscaler_v2" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = kubernetes_namespace_v1.nginx.metadata[0].name
    labels    = local.labels
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.nginx.metadata[0].name
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_average_utilization
        }
      }
    }

    behavior {
      scale_up {
        stabilization_window_seconds = 0
        select_policy                = "Max"
        policy {
          type           = "Percent"
          value          = 100
          period_seconds = 15
        }
      }
      scale_down {
        stabilization_window_seconds = 300
        select_policy                = "Max"
        policy {
          type           = "Percent"
          value          = 50
          period_seconds = 60
        }
      }
    }
  }
}
