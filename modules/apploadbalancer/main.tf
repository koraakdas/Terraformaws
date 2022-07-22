
resource "aws_lb_target_group" "lbtargetgrp" {
  name        = "${var.env_code}-LBTargetGrp"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpcid

  health_check {
    port     = 80
    protocol = "HTTP"

  }
}

resource "aws_lb" "applb" {
  name               = "${var.env_code}-AppLB"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  subnets            = [var.public0_subnet_id, var.public1_subnet_id]
  security_groups    = [var.lb_secgrp]
}

resource "aws_route53_record" "alias_record" {
  zone_id = var.domainzone
  name    = "www"
  type    = "A"

  alias {
    name                   = aws_lb.applb.dns_name
    zone_id                = aws_lb.applb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "acmcertificate" {
  domain_name       = "projectiac.link"
  validation_method = "DNS"

  tags = {
    Environment = "${var.env_code}-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "domain_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.acmcertificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.domainzone
}

resource "aws_acm_certificate_validation" "acmcertificate_validation" {
  certificate_arn         = aws_acm_certificate.acmcertificate.arn
  validation_record_fqdns = [for record in aws_route53_record.domain_validation_record : record.fqdn]
}

resource "aws_lb_listener" "httplstn" {
  load_balancer_arn = aws_lb.applb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.acmcertificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbtargetgrp.arn
  }
}

