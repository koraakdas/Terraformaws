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

data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket" "state_storage" {
  bucket = "projectiacbucket"
}

resource "aws_s3_bucket_acl" "state_storage_acl" {
  bucket = aws_s3_bucket.state_storage.id
  access_control_policy {
    grant {
      grantee {
        id   = "data.aws_canonical_user_id.current.id"
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    owner {
      id = "data.aws_canonical_user_id.current.id"
    }
  }
}

resource "aws_dynamodb_table" "lock" {
  name     = "projectiacdb"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
