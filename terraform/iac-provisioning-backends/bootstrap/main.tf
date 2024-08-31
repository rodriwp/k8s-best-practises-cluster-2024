terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.48.0"
    }
  }
}

locals {
  common_tags = {
    Service    = "IaC Backend"
    Automation = "Bootstrap"
  }
}

provider "aws" {
  region = "eu-west-2"
}

variable "bucket_id" {
  type = string
  default = "digger-rmompo-s3backend-iac-provisioning-backends"
}

variable "dynamo_lock_table_id" {
  type = string
  default = "digger-rmompo-locktable-iac-provisioning-backends"
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_id
  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "bucketLockTable" {
  name             = var.dynamo_lock_table_id
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  tags = local.common_tags
}