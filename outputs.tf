output "hosted_zone" {
  description = "The hosted zone for the site."
  value       = aws_route53_zone.site_zone.name
}

output "validation_names" {
  description = "The validation record names for the site."
  value       = aws_acm_certificate_validation.site_certificate_validation.validation_record_fqdns
}

output "validation_values" {
  description = "The validation record values for the sites."
  value       = [for record in aws_route53_record.site_validation : record.records]
}

output "site_private-dns" {
  description = "The private DNS for the available instances."
  value       = aws_instance.site_instance.*.private_dns
}

output "site_private" {
  description = "The private IP for the available instances."
  value       = aws_instance.site_instance.*.private_ip
}

output "site_public-dns" {
  description = "The public DNS for the available instances."
  value       = aws_eip.site_ec2_elastic_ip.*.public_dns
}

output "site_public" {
  description = "The public IP for the available instances."
  value       = aws_eip.site_ec2_elastic_ip.*.public_ip
}

output "site_lb" {
  description = "The record used by the load balancer."
  value       = aws_lb.site_lb.dns_name
}

output "test_policy_arn" {
  value = aws_iam_role.site_test_oidc.arn
}