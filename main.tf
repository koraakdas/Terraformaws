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

# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

    tags = {
    Name = "MYVPC"
  }
}

variable "public_subnet_cidr" {
  # Declaring a Variable to use as Count meta Function for two Public Subnets
  type    = list
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

resource "aws_subnet" "public" {

  count = 2

  vpc_id     = aws_vpc.myvpc.id
  cidr_block = var.public_subnet_cidr[count.index]
}

locals {
  # Declaring Local to use in count for the Private Suv=bnet

  private_subnet_cidr = ["10.0.3.0/24", "10.0.4.0/24"]
}

resource "aws_subnet" "private" {

  count = 2

  vpc_id     = aws_vpc.myvpc.id
  map_public_ip_on_launch = true
  cidr_block = local.private_subnet_cidr[count.index]
}

resource "aws_internet_gateway" "igw" {
   # Internet Gateway for the VPC for external Access
  vpc_id = aws_vpc.myvpc.id
}
resource "aws_eip" "eipnat" {
  count = 2
  vpc = true
}
resource "aws_nat_gateway" "ngw" {

  count = 2

  allocation_id = aws_eip.eipnat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}
resource "aws_route_table" "publicroute" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
resource "aws_route_table_association" "associatepub" {

  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.publicroute.id
}
resource "aws_route_table" "privateroute" {

  count = 2

  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[count.index].id
  }
}
resource "aws_route_table_association" "associatepriv" {

  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.privateroute[count.index].id
}

resource "aws_default_route_table" "defaultroute" {
  default_route_table_id = aws_vpc.myvpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

