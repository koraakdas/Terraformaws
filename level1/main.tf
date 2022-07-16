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

  env_code   = "ProjIAC"
  pubsubnet  = ["10.0.0.0/24", "10.0.1.0/24"]
  privsubnet = ["10.0.3.0/24", "10.0.4.0/24"]
  vpccidr    = "10.0.0.0/16"
  secgrpcidr = "0.0.0.0/0"
}
