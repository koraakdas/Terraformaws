terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "projectiacbucket"
    key            = "level2.tfstate"
    dynamodb_table = "projectiacdb"
    region         = "us-east-1"
  }
}

data "terraform_remote_state" "level1" {
  backend = "s3"
  config = {
    bucket = "projectiacbucket"
    key    = "level1.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
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
  subnets            = [data.terraform_remote_state.level1.outputs.public0_subnet_id, data.terraform_remote_state.level1.outputs.public1_subnet_id]
  security_groups    = [aws_security_group.lbsecgrp.id]
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

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["149500239764"]

  filter {
    name   = "name"
    values = ["ami-rhel8"]
  }
}

resource "aws_iam_policy" "s3policy" {
  name        = "s3_Policy"
  description = "Permission Level to access S3"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*",
          "s3-object-lambda:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ssmngpolicy" {
  name        = "SessionManager_Policy"
  description = "Instance Profile with Mession Manger Access"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "ec2instrole" {
  name = "EC2_InstanceRole"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "policy_role_attach1" {
  name       = "Instance_S3Policy_Attachment"
  roles      = [aws_iam_role.ec2instrole.name]
  policy_arn = aws_iam_policy.s3policy.arn
}

resource "aws_iam_policy_attachment" "policy_role_attach2" {
  name       = "Instance_SessionMgPolicy_Attachment"
  roles      = [aws_iam_role.ec2instrole.name]
  policy_arn = aws_iam_policy.ssmngpolicy.arn
}

resource "aws_iam_instance_profile" "ec2instprofile" {
  name = "EC2_instanceRole"
  role = aws_iam_role.ec2instrole.name
}

resource "aws_launch_template" "template" {
  name                                 = "${var.env_code}-ec2template"
  image_id                             = data.aws_ami.amazon_linux.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t2.micro"
  key_name                             = "main"
  vpc_security_group_ids               = [data.terraform_remote_state.level1.outputs.dfsecuritygrp, aws_security_group.instsecgrp.id]
  user_data                            = filebase64("instprep.sh")

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2instprofile.arn
  }
}

resource "aws_autoscaling_group" "autoscalegrp" {
  name                = "${var.env_code}-AutoScaleGrp"
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = [data.terraform_remote_state.level1.outputs.private0_subnet_id, data.terraform_remote_state.level1.outputs.private1_subnet_id]
  target_group_arns   = [aws_lb_target_group.lbtargetgrp.arn]


  launch_template {
    id = aws_launch_template.template.id
  }
}
