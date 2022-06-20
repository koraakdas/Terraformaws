terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket         = "projectiacbucket"
    key            = "instance.tfstate"
    dynamodb_table = "projectiacdb"
    region         = "us-east-1"
  }
}

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "projectiacbucket"
    key    = "networking.tfstate"
    region = "us-east-1"
  }
}


# Provider Block
provider "aws" {
  region = "us-east-1"
}

variable "env_code" {
  type        = string
  default     = "ProjectIAC"
  description = "Tag Naming Variable"
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
  subnet_id                   = data.terraform_remote_state.networking.outputs.public0_subnet_id
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