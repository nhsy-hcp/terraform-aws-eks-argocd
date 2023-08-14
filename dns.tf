data "aws_route53_zone" "default" {
  name         = var.domain
  private_zone = false
}

resource "aws_route53_record" "acm" {
  for_each = {
    for dvo in aws_acm_certificate.default.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.default.zone_id
}

resource "aws_acm_certificate_validation" "default" {
  certificate_arn         = aws_acm_certificate.default.arn
  validation_record_fqdns = [for record in aws_route53_record.acm : record.fqdn]
}

resource "aws_route53_record" "argocd" {
  zone_id = data.aws_route53_zone.default.zone_id
  name    = "argocd"
  type    = "CNAME"
  ttl     = 60
  records = [
    local.shared_alb_hostname
  ]
}

resource "aws_route53_record" "apps" {
  for_each = toset(["consul", "echoserver", "waypoint", "vault"])

  zone_id = data.aws_route53_zone.default.zone_id
  name    = each.value
  type    = "CNAME"
  ttl     = 60
  records = [
    local.shared_alb_hostname
  ]
}
