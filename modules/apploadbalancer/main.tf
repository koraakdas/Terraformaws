
data "terraform_remote_state" "level1" {
  backend = "s3"
  config = {
    bucket = "projectiacbucket"
    key    = "level1.tfstate"
    region = "us-east-1"
  }
}

module "securitygrps" {
  source = "../securitygrps"
  
}

resource "aws_lb_target_group" "lbtargetgrp" {
  name        = "${var.env_code}-LBTargetGrp"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.level1.outputs.vpcid

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
  subnets            = [data.terraform_remote_state.level1.outputs.public0subnet, data.terraform_remote_state.level1.outputs.public1subnet]
  security_groups    = [module.securitygrps.lb_secgrp]
}

resource "aws_lb_listener" "httplstn" {
  load_balancer_arn = aws_lb.applb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbtargetgrp.arn
  }
}

output "inst_secgrp" {
  value = module.securitygrps.inst_secgrp
}

output "lbtargetgrp_arn" {
  value = aws_lb_target_group.lbtargetgrp.arn
}