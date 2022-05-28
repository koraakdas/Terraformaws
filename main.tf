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
resource "aws_vpc" "kvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "kvpc"
  }
}
resource "aws_subnet" "public0" {
  vpc_id     = aws_vpc.kvpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "public0"
  }
}
resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.kvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public1"
  }
}
resource "aws_subnet" "private0" {
  vpc_id     = aws_vpc.kvpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private0"
  }
}
resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.kvpc.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "private1"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.kvpc.id

  tags = {
    Name = "igw"
  }
}
resource "aws_eip" "nat0" {
  vpc      = true
}
resource "aws_eip" "nat1" {
  vpc      = true
}
resource "aws_nat_gateway" "ngw0" {
  allocation_id = aws_eip.nat0.id
  subnet_id     = aws_subnet.public0.id

  tags = {
    Name = "gw NAT0"
  }
}
resource "aws_nat_gateway" "ngw1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "gw NAT1"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.kvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public"
  }
}
resource "aws_route_table" "private0" {
  vpc_id = aws_vpc.kvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw0.id
  }
  tags = {
    Name = "private0"
  }
}
resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.kvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw1.id
  }
  tags = {
    Name = "private1"
  }
}