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

  inst_secgrp = data.terraform_remote_state.level1.outputs.inst_secgrp
  private0subnet = data.terraform_remote_state.level1.outputs.private0subnet
  private1subnet = data.terraform_remote_state.level1.outputs.private1subnet
  lbtargetgrp_arn = data.terraform_remote_state.level1.outputs.lbtargetgrp_arn
}
