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

resource "aws_lb_target_group" "lbtargetgrp" {
  name        = "${var.env_code}-LBTargetGrp"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.level1.outputs.vpcid
}

resource "aws_lb" "applb" {
  name               = "${var.env_code}-AppLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.level1.outputs.dfsecuritygrp]
  subnets            = [data.terraform_remote_state.level1.outputs.public0_subnet_id, data.terraform_remote_state.level1.outputs.public1_subnet_id]
  
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

resource "aws_lb_target_group_attachment" "targetgrpattch" {
  target_group_arn = aws_lb_target_group.lbtargetgrp.arn
  port             = "80"
  target_id        = aws_instance.apacheweb.id
  depends_on = [
    aws_instance.apacheweb
  ]
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["149500239764"]

  filter {
    name   = "name"
    values = ["ami-rhel8"]
  }
}

resource "aws_instance" "apacheweb" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = data.terraform_remote_state.level1.outputs.public0_subnet_id
  associate_public_ip_address = true
  key_name                    = "main"
  user_data                   = <<EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd.service
systemctl enable httpd.service
echo "The page was created by the user data" | tee /var/www/html/index.html
EOF

  tags = {
    Name = "${var.env_code}InstancePublic"
  }
}
