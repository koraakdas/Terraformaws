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

provider "aws" {
  region = "us-east-1"
}

module "ec2instance" {
  source = "../modules/ec2"
}
