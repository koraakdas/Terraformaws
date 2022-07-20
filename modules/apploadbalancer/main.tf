
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

resource "aws_route53_record" "www" {
  zone_id = var.domainzone
  name    = "www"
  type    = "A"

  alias {
    name                   = aws_lb.applb.dns_name
    zone_id                = aws_lb.applb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "projectiac.link"
  validation_method = "DNS"

  tags = {
    Environment = "${var.env_code}-Cert"
  }
}

resource "aws_acm_certificate_validation" "dnsvalidation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.www.fqdn]
}

resource "aws_lb_listener" "httplstn" {
  load_balancer_arn = aws_lb.applb.arn
  port              = "80"
  protocol          = "HTTP"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbtargetgrp.arn
  }
}
