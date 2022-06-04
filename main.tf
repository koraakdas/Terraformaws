terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

variable "env_code" {
  type        = string
  default     = "MyTest"
  description = "Tag Naming Variable"
}


# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.env_code}-VPC"
  }
}


locals {
  # Declaring Locals to use in aws_subnet resource blocks

  public_subnet_cidr  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidr = ["10.0.3.0/24", "10.0.4.0/24"]
}


resource "aws_subnet" "public" {
  # Defining Public subnets
  count = length(local.public_subnet_cidr)

  vpc_id     = aws_vpc.myvpc.id
  cidr_block = local.public_subnet_cidr[count.index]

  tags = {
    Name = "${var.env_code} Public${count.index}-Subnet"
  }
}


resource "aws_subnet" "private" {
  # Defining Private subnets
  count = length(local.private_subnet_cidr)

  vpc_id     = aws_vpc.myvpc.id
  cidr_block = local.private_subnet_cidr[count.index]

  tags = {
    Name = "${var.env_code} Private${count.index}-Subnet"
  }
}


resource "aws_internet_gateway" "igw" {
  # Internet Gateway for VPC's External Access

  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "${var.env_code}-IGW"
  }
}


resource "aws_eip" "eipnat" {
  # Defining Elastic IP for Each Nat Gateway
  count = length(local.private_subnet_cidr)

  vpc = true

  tags = {
    Name = "${var.env_code}-EIP_NAT${count.index}"
  }
}


resource "aws_nat_gateway" "ngw" {
  # Defining Nat Gateway for Private Subnets
  count = length(local.private_subnet_cidr)

  allocation_id = aws_eip.eipnat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.env_code}-NGW${count.index}"
  }
}


resource "aws_route_table" "publicroute" {
  # Public Route Table

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
  #Public Route Table Associations
  count = length(local.public_subnet_cidr)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.publicroute.id
}


resource "aws_route_table" "privateroute" {
  #Public Route Table
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
  #Private Route Table Associations
  count = length(local.private_subnet_cidr)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.privateroute[count.index].id
}
