# /modules/s3-state/main.tf
/*** S3 Bucket for storing Terraform state ***/

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "state_s3" {
  bucket = var.bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state_s3" {
  bucket = aws_s3_bucket.state_s3.id

  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state_s3" {
  bucket = aws_s3_bucket.state_s3.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.state_s3]
}

resource "aws_kms_key" "this" {
  description             = "Encrypts Terraform state objects in ${var.bucket_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.bucket_name}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_s3" {
  bucket = aws_s3_bucket.state_s3.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state_s3" {
  bucket = aws_s3_bucket.state_s3.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state_s3" {
  bucket = aws_s3_bucket.state_s3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

/*** S3 Bucket Trust Policy ***/
resource "aws_s3_bucket_policy" "state_s3" {
  bucket = aws_s3_bucket.state_s3.id

  depends_on = [aws_s3_bucket_public_access_block.state_s3]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforcedTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.state_s3.id}",
          "arn:aws:s3:::${aws_s3_bucket.state_s3.id}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = var.deploy_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.state_s3.id}",
          "arn:aws:s3:::${aws_s3_bucket.state_s3.id}/*"
        ]
      }
    ]
  })
}
