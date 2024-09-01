terraform {
  required_version = ">=1.8.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.65.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.5"
    }
  }

  backend "s3" {}
}
