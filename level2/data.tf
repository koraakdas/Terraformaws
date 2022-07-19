
data "terraform_remote_state" "level1" {
  backend = "s3"
  config = {
    bucket = "projectiacbucket"
    key    = "level1.tfstate"
    region = "us-east-1"
  }
}

data "aws_route53_zone" "projectiaczone" {
  name         = "projectiac.link"
}
