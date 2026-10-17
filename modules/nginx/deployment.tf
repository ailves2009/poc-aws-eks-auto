# modules/nginx/deployment.tf

locals {
  labels = {
    "app.kubernetes.io/name"       = "nginx-demo"
    "app.kubernetes.io/managed-by" = "terraform"
  }
  selector = {
    "app.kubernetes.io/name" = "nginx-demo"
  }
}

resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = kubernetes_namespace_v1.nginx.metadata[0].name
    labels    = local.labels
  }

  spec {
    # Initial size only; the HPA owns the replica count afterwards.
    replicas = var.hpa_min_replicas

    selector {
      match_labels = local.selector
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        # Land on the custom Auto Mode NodePool (Graviton, Spot first).
        node_selector = {
          "workload-tier" = var.node_pool
        }

        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "topology.kubernetes.io/zone"
          when_unsatisfiable = "ScheduleAnyway"
          label_selector {
            match_labels = local.selector
          }
        }

        security_context {
          run_as_non_root = true
          run_as_user     = 101
          run_as_group    = 101
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "nginx"
          image = var.image

          port {
            name           = "http"
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            period_seconds = 5
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 10
            period_seconds        = 20
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
        }

        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [spec[0].replicas]
  }
}

resource "kubernetes_pod_disruption_budget_v1" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = kubernetes_namespace_v1.nginx.metadata[0].name
    labels    = local.labels
  }

  spec {
    min_available = 1
    selector {
      match_labels = local.selector
    }
  }
}
