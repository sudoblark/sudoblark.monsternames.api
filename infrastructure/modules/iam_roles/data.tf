locals {
  known_buckets = {
    assets : {
      name : lower("${var.environment}-${var.application_name}-assets")
      arn : lower("arn:aws:s3:::${var.environment}-${var.application_name}-assets")
    },
  }
  known_kms_keys = {
    "assets-bucket" : lower("alias/${var.environment}-${var.application_name}-assets"),
  }
}

# Get current account
data "aws_caller_identity" "current" {}

# Lookup known KMS keys for easy reference across stack
data "aws_kms_key" "known_keys" {
  for_each = local.known_kms_keys
  key_id   = each.value
}