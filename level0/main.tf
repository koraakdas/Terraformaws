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

resource "aws_s3_bucket" "state_storage" {
}

resource "aws_dynamodb_table" "lock" {
}
