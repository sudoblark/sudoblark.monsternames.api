locals {
  known_lambda_names = {
    "backend-lambda" : lower("aws-${var.environment}-${var.application_name}-backend-lambda"),
  }
  known_buckets = {
    assets : {
      name : lower("${var.environment}-${var.application_name}-assets")
      arn : lower("arn:aws:s3:::${var.environment}-${var.application_name}-assets")
    }
  }
  known_roles = {
    api_gateway_iam_role_arn : {
      name : lower("aws-${var.environment}-${var.application_name}-api-gateway-role"),
      arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-${var.environment}-${var.application_name}-api-gateway-role"
    }
  }
}

# Lookup known lambdas for easy reference in across stack
data "aws_lambda_function" "known_lambdas" {
  for_each      = local.known_lambda_names
  function_name = each.value
}

# Get current region
data "aws_region" "current_region" {}

# Get current account
data "aws_caller_identity" "current" {}



