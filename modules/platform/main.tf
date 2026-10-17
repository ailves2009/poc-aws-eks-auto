# /modules/platform/main.tf
#
# Cluster-level Kubernetes objects for EKS Auto Mode. Kept out of the eks stack
# because kubernetes_manifest needs a reachable API server (and the Auto Mode
# CRDs) at plan time.

################################################################################
# NodePool for application workloads
#
# Auto Mode ships the "general-purpose" and "system" NodePools. This one shows
# how to steer workloads with plain Karpenter v1 API objects that reference the
# built-in "default" NodeClass: Graviton only, Spot preferred with On-Demand
# fallback, consolidation of under-utilised nodes.
################################################################################

resource "kubernetes_manifest" "apps_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = var.apps_node_pool.name
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "workload-tier" = var.apps_node_pool.name
          }
        }
        spec = {
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "default"
          }
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = var.apps_node_pool.architectures
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = var.apps_node_pool.capacity_types
            },
            {
              key      = "eks.amazonaws.com/instance-category"
              operator = "In"
              values   = var.apps_node_pool.instance_categories
            },
            {
              key      = "eks.amazonaws.com/instance-generation"
              operator = "Gt"
              values   = [tostring(var.apps_node_pool.min_instance_generation - 1)]
            },
          ]
          expireAfter = "336h"
        }
      }
      limits = {
        cpu    = tostring(var.apps_node_pool.cpu_limit)
        memory = var.apps_node_pool.memory_limit
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "1m"
      }
    }
  }
}

################################################################################
# Public ALB ingress class (Auto Mode built-in load balancing)
################################################################################

resource "kubernetes_manifest" "alb_ingress_class_params" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "IngressClassParams"
    metadata = {
      name = "alb-public"
    }
    spec = {
      scheme          = "internet-facing"
      certificateARNs = [var.certificate_arn]
      sslPolicy       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    }
  }
}

resource "kubernetes_ingress_class_v1" "alb" {
  metadata {
    name = "alb"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "true"
    }
  }

  spec {
    controller = "eks.amazonaws.com/alb"
    parameters {
      api_group = "eks.amazonaws.com"
      kind      = "IngressClassParams"
      name      = kubernetes_manifest.alb_ingress_class_params.manifest.metadata.name
    }
  }
}
