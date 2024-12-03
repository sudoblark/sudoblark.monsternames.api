locals {
  known_lambda_names = {
    "backend-lambda" : lower("aws-${var.environment}-${var.application_name}-backend-lambda"),
  }
}

# Lookup known lambdas for easy reference in across stack
data "aws_lambda_function" "known_lambdas" {
  for_each      = local.known_lambda_names
  function_name = each.value
}

# Get current region
data "aws_region" "current_region" {}