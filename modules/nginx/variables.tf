# modules/nginx/variables.tf

variable "namespace" {
  description = "Kubernetes namespace for the demo app"
  type        = string
  default     = "nginx"
}

variable "hostname" {
  description = "Public hostname; external-dns creates the Route53 record for it"
  type        = string
}

variable "ingress_class_name" {
  description = "IngressClass backed by the EKS Auto Mode ALB controller"
  type        = string
  default     = "alb"
}

variable "node_pool" {
  description = "Value of the workload-tier node label of the target NodePool"
  type        = string
  default     = "apps"
}

variable "image" {
  description = "Container image (unprivileged nginx, listens on 8080)"
  type        = string
  default     = "nginxinc/nginx-unprivileged:1.30-alpine"
}

variable "hpa_average_utilization" {
  description = "Target average CPU utilization (percent of requests)"
  type        = number
  default     = 70
}

variable "hpa_min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 10
}

variable "cpu_request" {
  description = "CPU request for the nginx container"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for the nginx container"
  type        = string
  default     = "64Mi"
}

variable "cpu_limit" {
  description = "CPU limit for the nginx container"
  type        = string
  default     = "250m"
}

variable "memory_limit" {
  description = "Memory limit for the nginx container"
  type        = string
  default     = "128Mi"
}
