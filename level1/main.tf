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

  env_code = "ProjIAC"
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

module "securitygrps" {
  source = "../modules/securitygrps"

  vpcid = module.vpc.vpcid

}

output "inst_secgrp" {
  value = module.securitygrps.inst_secgrp
}

module "apploadbalancer" {
  source = "../modules/apploadbalancer"

  env_code = "ProjIAC"
  vpcid = module.vpc.vpcid
  lb_secgrp = module.securitygrps.lb_secgrp
  public0_subnet_id = module.vpc.public0_subnet_id
  public1_subnet_id = module.vpc.public1_subnet_id

}

output "lbtargetgrp_arn" {
  value = module.apploadbalancer.lbtargetgrp_arn
}