output "s3_buckets" {
  description = "Created S3 buckets"
  value       = module.s3.buckets
}

output "iam_roles" {
  description = "Created IAM roles"
  value       = module.iam.roles
}

output "lambda_functions" {
  description = "Created Lambda functions"
  value       = module.lambda.lambdas
}

output "api_gateway_urls" {
  description = "API Gateway invoke URLs"
  value       = module.api_gateway.api_gateway_urls
}

output "api_keys" {
  description = "API Gateway keys"
  value       = module.api_gateway.api_keys
  sensitive   = true
}
