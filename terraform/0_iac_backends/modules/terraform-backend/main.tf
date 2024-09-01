locals {
  common_tags = {
    Service    = "ÏIaC Backend"
    Automation = "Terraform"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "digger-s3backend-${var.backend_name}"
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
  name             = "digger-locktable-${var.backend_name}"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  tags = local.common_tags
}