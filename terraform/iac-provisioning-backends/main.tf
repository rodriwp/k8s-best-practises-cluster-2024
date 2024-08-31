locals {
  common_tags = {
    Service    = "IaC Backend"
    Automation = "Terraform"
  }
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/automation-deployment-role"
  }

}

module "automation_group" {
  source   = "modules/terraform-backend"
  for_each = toset(var.backend_names_list)
  backend_name     = each.value
}