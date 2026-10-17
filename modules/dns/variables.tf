# modules/dns/variables.tf

variable "domain_name" {
  description = "Domain name of the hosted zone (e.g. nyd-plt.ailves2009.com)"
  type        = string
}

variable "create_zone" {
  description = "Create the hosted zone (true) or look up an existing one (false)"
  type        = bool
  default     = true
}

variable "comment" {
  description = "Comment for the hosted zone"
  type        = string
  default     = "Managed by Terraform (poc-aws-eks-auto)"
}

variable "force_destroy" {
  description = "Allow deleting the zone even if it still has records (e.g. left by external-dns)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for the hosted zone"
  type        = map(string)
  default     = {}
}
