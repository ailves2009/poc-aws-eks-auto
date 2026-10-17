# modules/nginx/service.tf

resource "kubernetes_service_v1" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = kubernetes_namespace_v1.nginx.metadata[0].name
    labels    = local.labels
  }

  spec {
    type     = "ClusterIP"
    selector = local.selector

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = "http"
    }
  }
}
