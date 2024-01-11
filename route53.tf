resource "aws_route53_zone" "site_zone" {
  name = var.site_domain
}

resource "aws_acm_certificate" "site_certificate" {
  domain_name = var.site_domain
  subject_alternative_names = [
    "www.${var.site_domain}"
  ]
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "site_validation" {
  for_each = {
    for d in aws_acm_certificate.site_certificate.domain_validation_options : d.domain_name => {
      name   = d.resource_record_name
      record = d.resource_record_value
      type   = d.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = var.site_ttl
  type            = each.value.type
  zone_id         = aws_route53_zone.site_zone.zone_id
}

resource "aws_acm_certificate_validation" "site_certificate_validation" {
  certificate_arn         = aws_acm_certificate.site_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.site_validation : record.fqdn]
}