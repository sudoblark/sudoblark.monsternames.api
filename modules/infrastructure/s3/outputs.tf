output "buckets" {
  description = "Map of created S3 buckets with their attributes"
  value = {
    for name, bucket in aws_s3_bucket.bucket : name => {
      id                          = bucket.id
      arn                         = bucket.arn
      bucket                      = bucket.bucket
      bucket_domain_name          = bucket.bucket_domain_name
      bucket_regional_domain_name = bucket.bucket_regional_domain_name
    }
  }
}

output "bucket_ids" {
  description = "Map of bucket names to IDs"
  value = {
    for name, bucket in aws_s3_bucket.bucket : name => bucket.id
  }
}

output "bucket_arns" {
  description = "Map of bucket names to ARNs"
  value = {
    for name, bucket in aws_s3_bucket.bucket : name => bucket.arn
  }
}
