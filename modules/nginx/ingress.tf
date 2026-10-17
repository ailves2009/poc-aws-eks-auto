# modules/nginx/ingress.tf
#
# EKS Auto Mode's built-in load balancing provisions an internet-facing ALB
# for this Ingress (scheme and ACM certificate come from the IngressClassParams
# in modules/platform). external-dns sees the host rule and creates the
# Route53 record that points at the ALB, so Terraform never waits on the ALB hostname.

resource "kubernetes_ingress_v1" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = kubernetes_namespace_v1.nginx.metadata[0].name
    labels    = local.labels

    annotations = {
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
      "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.nginx.metadata[0].name
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }

  wait_for_load_balancer = true
}
