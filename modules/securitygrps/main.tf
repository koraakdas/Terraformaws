
data "terraform_remote_state" "level1" {
  backend = "s3"
  config = {
    bucket = "projectiacbucket"
    key    = "level1.tfstate"
    region = "us-east-1"
  }
}

resource "aws_security_group" "instsecgrp" {
  name        = "InstanceSecurityGrp"
  description = "Additional Sec Grp for Instances"
  vpc_id      = data.terraform_remote_state.level1.outputs.vpcid
}


resource "aws_security_group" "lbsecgrp" {
  name        = "LBSecurityGrp"
  description = "App Load Blancer Rules"
  vpc_id      = data.terraform_remote_state.level1.outputs.vpcid

  ingress {
    description = "load balancer listener port traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "instance listener and health check rule"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.instsecgrp.id]
  }
}

resource "aws_security_group_rule" "rule1" {
  description              = "lb to inst security grp ingress"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.instsecgrp.id
  source_security_group_id = aws_security_group.lbsecgrp.id
}

resource "aws_security_group_rule" "rule2" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instsecgrp.id
}

output "inst_secgrp" {
  value = aws_security_group.instsecgrp.id
}

output "lb_secgrp" {
  value = aws_security_group.lbsecgrp.id
}