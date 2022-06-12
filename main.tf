terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
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

variable "client_public_ip" {
  type        = string
  default     = "192.168.1.116/24"
  description = "client IP address"
}

# All Resources for AWS:

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.env_code}-VPC"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["var.client_public_ip"]
  }

  ingress {
    protocol    = ""
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["var.client_public_ip"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_code}DefaultSecurityGrp"
  }
}

locals {
  public_subnet_cidr  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidr = ["10.0.3.0/24", "10.0.4.0/24"]
}

resource "aws_subnet" "public" {
  count = length(local.public_subnet_cidr)

  vpc_id     = aws_vpc.myvpc.id
  cidr_block = local.public_subnet_cidr[count.index]

  tags = {
    Name = "${var.env_code} Public${count.index}-Subnet"
  }
}

resource "aws_subnet" "private" {
  count = length(local.private_subnet_cidr)

  vpc_id     = aws_vpc.myvpc.id
  cidr_block = local.private_subnet_cidr[count.index]

  tags = {
    Name = "${var.env_code} Private${count.index}-Subnet"
  }
}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "${var.env_code}-IGW"
  }
}

resource "aws_eip" "eipnat" {
  count = length(local.private_subnet_cidr)

  vpc = true

  tags = {
    Name = "${var.env_code}-EIP_NAT${count.index}"
  }
}

resource "aws_nat_gateway" "ngw" {
  count = length(local.private_subnet_cidr)

  allocation_id = aws_eip.eipnat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.env_code}-NGW${count.index}"
  }
}

resource "aws_route_table" "publicroute" {

  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env_code}-PublicRouteTable"
  }
}

resource "aws_route_table_association" "associatepub" {
  count = length(local.public_subnet_cidr)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.publicroute.id
}

resource "aws_route_table" "privateroute" {
  count = length(local.private_subnet_cidr)

  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[count.index].id
  }

  tags = {
    Name = "${var.env_code}-PrivateRouteTable${count.index}"
  }
}

resource "aws_route_table_association" "associatepriv" {
  count = length(local.private_subnet_cidr)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.privateroute[count.index].id
}

resource "aws_instance" "apacheweb" {
  count = 1

  ami                         = "ami-0f095f89ae15be883"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  key_name                    = "main"
  user_data                   = <<EOF

  #! /bin/bash
  sudo yum update -y
  sudo yum install -y httpd
  sudo systemctl start httpd.service
  sudo systemctl enable httpd.service
  echo "The page was created by the user data" | sudo tee /var/www/html/index.html

  EOF

  tags = {
    Name = "${var.env_code}InstancePublic"
  }
}