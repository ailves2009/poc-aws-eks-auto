# /modules/eks/main.tf
#
# EKS cluster in Auto Mode. AWS runs the data plane components that the
# previous version of this POC installed by hand:
#   - node provisioning/scaling (managed Karpenter)  -> replaces Cluster Autoscaler + managed node group
#   - ALB/NLB provisioning                            -> replaces AWS Load Balancer Controller (Helm + IRSA)
#   - VPC CNI, kube-proxy, CoreDNS, EBS CSI, Pod Identity agent
# Only metrics-server and external-dns are added, as EKS community add-ons.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  endpoint_private_access      = true

  # Access entries only (no aws-auth ConfigMap); the caller becomes cluster admin.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  # Pod Identity is used for all workload IAM, so no IRSA / OIDC provider.
  enable_irsa = false

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose", "system"]
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  addons = {
    metrics-server = {}

    external-dns = {
      configuration_values = jsonencode({
        domainFilters = [var.domain_name]
        policy        = "sync"
        sources       = ["ingress", "service"]
        txtOwnerId    = var.cluster_name
        env = [{
          name  = "AWS_DEFAULT_REGION"
          value = var.region
        }]
      })
      pod_identity_association = [{
        role_arn        = aws_iam_role.external_dns.arn
        service_account = "external-dns"
      }]
    }
  }

  tags = var.tags
}

################################################################################
# external-dns IAM role (EKS Pod Identity)
################################################################################

data "aws_iam_policy_document" "external_dns_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:eks:${var.region}:${var.account}:cluster/${var.cluster_name}"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_trust.json
  tags               = var.tags
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = [var.zone_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResources",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "external_dns" {
  name   = "route53-records"
  role   = aws_iam_role.external_dns.id
  policy = data.aws_iam_policy_document.external_dns.json
}
