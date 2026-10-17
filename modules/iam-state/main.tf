# /modules/iam-state/main.tf
#
# CI/CD role that can deploy envs/main. Permissions are scoped to what the
# stacks create: IAM roles/policies are limited to "<cluster_name>-*" (the EKS
# module and external-dns role use that prefix) plus the VPC flow-log role,
# EKS actions to the one cluster, and destructive KMS/log actions to resources
# that belong to this project. EC2 stays broad (the VPC module touches dozens
# of EC2 APIs) but is pinned to the deployment region.

locals {
  iam_role_arns = [
    "arn:aws:iam::${var.account}:role/${var.cluster_name}-*",
    "arn:aws:iam::${var.account}:role/vpc-flow-log-role-*",
  ]
  iam_policy_arns = [
    "arn:aws:iam::${var.account}:policy/${var.cluster_name}-*",
    "arn:aws:iam::${var.account}:policy/vpc-flow-log-to-cloudwatch-*",
  ]
  region_condition = {
    test     = "StringEquals"
    variable = "aws:RequestedRegion"
    values   = [var.region]
  }
}

resource "aws_iam_role" "deploy_assume_role" {
  name               = var.cicd_role_name
  assume_role_policy = data.aws_iam_policy_document.deploy_assume_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "deploy_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [var.cicd_account_arn]
    }
  }
}

################################################################################
# Terraform state access
################################################################################

data "aws_iam_policy_document" "state" {
  statement {
    sid       = "StateBucketList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.s3_terraform_state}"]
  }

  statement {
    sid       = "StateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.s3_terraform_state}/*"]
  }

  # The bucket is encrypted with a customer managed KMS key.
  statement {
    sid       = "StateKms"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "state" {
  name        = "${var.cicd_role_name}-state"
  description = "Terraform state access for the CI/CD role"
  policy      = data.aws_iam_policy_document.state.json
}

resource "aws_iam_role_policy_attachment" "state" {
  role       = aws_iam_role.deploy_assume_role.name
  policy_arn = aws_iam_policy.state.arn
}

################################################################################
# Infrastructure deployment
################################################################################

data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "Ec2Networking"
    effect    = "Allow"
    actions   = ["ec2:*"]
    resources = ["*"]

    condition {
      test     = local.region_condition.test
      variable = local.region_condition.variable
      values   = local.region_condition.values
    }
  }

  statement {
    sid     = "EksCluster"
    effect  = "Allow"
    actions = ["eks:*"]
    resources = [
      "arn:aws:eks:${var.region}:${var.account}:cluster/${var.cluster_name}",
      "arn:aws:eks:${var.region}:${var.account}:*/${var.cluster_name}/*",
    ]
  }

  statement {
    sid    = "EksRead"
    effect = "Allow"
    actions = [
      "eks:DescribeAddonConfiguration",
      "eks:DescribeAddonVersions",
      "eks:DescribeClusterVersions",
      "eks:ListClusters",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IamRead"
    effect = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IamProjectRoles"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
    ]
    resources = local.iam_role_arns
  }

  statement {
    sid    = "IamProjectPolicies"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = local.iam_policy_arns
  }

  statement {
    sid       = "IamServiceLinkedRoles"
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "eks.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "spot.amazonaws.com",
      ]
    }
  }

  statement {
    sid       = "KmsCreate"
    effect    = "Allow"
    actions   = ["kms:CreateKey", "kms:ListAliases", "kms:TagResource"]
    resources = ["*"]
  }

  statement {
    sid     = "KmsAliases"
    effect  = "Allow"
    actions = ["kms:CreateAlias", "kms:DeleteAlias", "kms:UpdateAlias"]
    resources = [
      "arn:aws:kms:${var.region}:${var.account}:alias/eks/${var.cluster_name}",
      "arn:aws:kms:${var.region}:${var.account}:key/*",
    ]
  }

  # Key management only for keys tagged by this project's default_tags, so
  # the role cannot schedule deletion of unrelated keys (e.g. the state key).
  statement {
    sid    = "KmsProjectKeys"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:DescribeKey",
      "kms:EnableKeyRotation",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags",
      "kms:PutKeyPolicy",
      "kms:ScheduleKeyDeletion",
      "kms:UntagResource",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_tag]
    }
  }

  statement {
    sid       = "LogsRead"
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups", "logs:ListTagsForResource"]
    resources = ["*"]
  }

  statement {
    sid    = "LogsProjectGroups"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${var.account}:log-group:/aws/eks/${var.cluster_name}/*",
      "arn:aws:logs:${var.region}:${var.account}:log-group:/aws/vpc-flow-log/*",
    ]
  }

  statement {
    sid    = "CertificatesDnsMonitoring"
    effect = "Allow"
    actions = [
      "acm:*",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DeleteDashboards",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:GetDashboard",
      "cloudwatch:ListTagsForResource",
      "cloudwatch:PutDashboard",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:TagResource",
      "route53:ChangeResourceRecordSets",
      "route53:ChangeTagsForResource",
      "route53:CreateHostedZone",
      "route53:DeleteHostedZone",
      "route53:GetChange",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
      "sns:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "deploy" {
  name        = "${var.cicd_role_name}-deploy"
  description = "Infrastructure deployment permissions for the CI/CD role"
  policy      = data.aws_iam_policy_document.deploy.json
}

resource "aws_iam_role_policy_attachment" "deploy" {
  role       = aws_iam_role.deploy_assume_role.name
  policy_arn = aws_iam_policy.deploy.arn
}
