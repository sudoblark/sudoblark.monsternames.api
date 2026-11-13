# Output all created S3 buckets
output "s3_buckets" {
  description = "All created S3 buckets with their properties"
  value       = module.s3.buckets
}

# Output all created DynamoDB tables
output "dynamodb_tables" {
  description = "All created DynamoDB tables with their properties"
  value       = module.dynamodb.tables
}

# Output all created IAM roles, by what assumes them
output "iam_roles" {
  description = "All created IAM roles, keyed by the Lambda or API that assumes them, plus API Gateway's account-wide logging role"
  value = {
    lambdas = {
      for name, lambda in module.lambda.lambdas : name => {
        name = lambda.role_name
        arn  = lambda.role_arn
      }
    }
    api_gateways = {
      for name, api in module.api_gateway.api_gateways : name => {
        name = api.role_name
        arn  = api.role_arn
      } if api.role_name != null
    }
    api_gateway_account = {
      name = module.api_gateway_account.cloudwatch_role_name
      arn  = module.api_gateway_account.cloudwatch_role_arn
    }
  }
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
