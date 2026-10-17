# modules/nginx/namespace.tf

resource "kubernetes_namespace_v1" "nginx" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}
