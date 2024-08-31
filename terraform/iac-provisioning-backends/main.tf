locals {
  common_tags = {
    Service    = "Lynceus IaC Backend"
    Automation = "Terraform"
  }
}

provider "aws" {
  region = "eu-west-2"
}

module "automation_group" {
  source   = "modules/terraform-backend"
  for_each = toset(var.backend_names_list)
  backend_name     = each.value
}