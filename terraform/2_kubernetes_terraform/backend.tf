terraform {
  required_version = ">=1.8.1"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.32.0"
    }
  }

  backend "s3" {}
}
