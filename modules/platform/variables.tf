# /modules/platform/variables.tf

variable "certificate_arn" {
  description = "ACM certificate attached to ALBs created through the \"alb\" IngressClass"
  type        = string
}

variable "apps_node_pool" {
  description = "Custom Auto Mode NodePool for application workloads"
  type = object({
    name                    = optional(string, "apps")
    architectures           = optional(list(string), ["arm64"])
    capacity_types          = optional(list(string), ["spot", "on-demand"])
    instance_categories     = optional(list(string), ["c", "m"])
    min_instance_generation = optional(number, 6)
    cpu_limit               = optional(number, 16)
    memory_limit            = optional(string, "64Gi")
  })
  default = {}
}
