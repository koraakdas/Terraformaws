terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket         = "projectiacbucket"
    key            = "level1.tfstate"
    dynamodb_table = "projectiacdb"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../modules/vpc"
}

output "public0subnet" {
  value = module.vpc.public0_subnet_id
}

output "public1subnet" {
  value = module.vpc.public1_subnet_id
}

output "private0subnet" {
  value = module.vpc.private0_subnet_id
}

output "private1subnet" {
  value = module.vpc.private1_subnet_id
}

output "vpcid" {
  value = module.vpc.vpcid
}
