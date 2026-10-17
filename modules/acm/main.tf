# /modules/acm/main.tf

# Main ACM certificate for the domain and wildcard
resource "aws_acm_certificate" "wildcard" {
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"

  tags = merge(var.tags, {
    Name = "wildcard-${var.domain_name}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Additional certificate for CloudFront in us-east-1
resource "aws_acm_certificate" "cloudfront_wildcard" {
  count                     = var.create_cloudfront_certificate ? 1 : 0
  provider                  = aws.us_east_1
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"

  tags = merge(var.tags, {
    Name    = "CloudFront-${var.domain_name}"
    Purpose = "CloudFront-SSL"
    Region  = "us-east-1"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id         = var.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Route53 records for CloudFront certificate validation
resource "aws_route53_record" "cloudfront_validation" {
  for_each = var.create_cloudfront_certificate ? {
    for dvo in aws_acm_certificate.cloudfront_wildcard[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id         = var.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# CloudFront certificate validation
resource "aws_acm_certificate_validation" "cloudfront" {
  count                   = var.create_cloudfront_certificate ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront_wildcard[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_validation : record.fqdn]
}
