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

module "securitygrps" {
  source = "../modules/securitygrps"

  vpcid = data.terraform_remote_state.level1.outputs.vpcid

}

module "apploadbalancer" {
  source = "../modules/apploadbalancer"

  env_code = "ProjIAC"
  vpcid = data.terraform_remote_state.level1.outputs.vpcid
  lb_secgrp = module.securitygrps.lb_secgrp
  public0_subnet_id = data.terraform_remote_state.level1.outputs.public0subnet
  public1_subnet_id = data.terraform_remote_state.level1.outputs.public1subnet

}

module "ec2instance" {
  source = "../modules/ec2"

  inst_secgrp = module.securitygrps.inst_secgrp
  private0subnet = data.terraform_remote_state.level1.outputs.private0subnet
  private1subnet = data.terraform_remote_state.level1.outputs.private1subnet
  lbtargetgrp_arn = module.apploadbalancer.lbtargetgrp_arn
}
