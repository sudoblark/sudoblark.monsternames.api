# Output all created S3 buckets
output "s3_buckets" {
  description = "All created S3 buckets with their properties"
  value       = module.s3.buckets
}

# Output all created IAM roles
output "iam_roles" {
  description = "All created IAM roles with their properties"
  value       = module.iam.roles
}

# Output all created Lambda functions
output "lambda_functions" {
  description = "All created Lambda functions with their properties"
  value       = module.lambda.lambdas
}

# Output all created S3 files
output "s3_files" {
  description = "All S3 files uploaded with their properties"
  value       = module.s3_files.uploaded_files
}

# Output API Gateway details
output "api_gateways" {
  description = "All created API Gateways with their properties"
  value       = module.api_gateway.api_gateways
}

# Output API Gateway stages and URLs
output "api_gateway_stages" {
  description = "API Gateway stages with invoke URLs"
  value       = module.api_gateway.api_gateway_stages
}

# Output API Gateway invoke URLs (convenient)
output "api_gateway_urls" {
  description = "API Gateway invoke URLs"
  value       = module.api_gateway.api_gateway_urls
}

# Output API keys (sensitive)
output "api_keys" {
  description = "API Gateway keys for authenticated access"
  value       = module.api_gateway.api_keys
  sensitive   = true
}

# Output Application Registry
output "application_registry" {
  description = "Service Catalog Application Registry details"
  value = {
    application_id  = aws_servicecatalogappregistry_application.application.id
    application_arn = aws_servicecatalogappregistry_application.application.arn
    application_tag = aws_servicecatalogappregistry_application.application.application_tag
  }
}
