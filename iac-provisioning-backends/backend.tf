terraform {
  required_version = ">=1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.65.0"
    }
  }

  backend "s3" {
    bucket = "digger-s3backend-iac-provisioning-backends"
    dynamodb_table = "digger-locktable-iac-provisioning-backends"

    key    = "terraform/state"
    region = "eu-west-2"
  }
}
