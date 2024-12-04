locals {
  known_buckets = {
    assets : {
      name : lower("${var.environment}-${var.application_name}-assets")
      arn : lower("arn:aws:s3:::${var.environment}-${var.application_name}-assets")
    },
  }
}
