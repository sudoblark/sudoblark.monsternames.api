output "lambdas" {
  description = "Map of created Lambda functions with their attributes"
  value = {
    for name, lambda in aws_lambda_function.lambda : name => {
      arn                            = lambda.arn
      function_name                  = lambda.function_name
      invoke_arn                     = lambda.invoke_arn
      qualified_arn                  = lambda.qualified_arn
      version                        = lambda.version
      last_modified                  = lambda.last_modified
      source_code_hash               = lambda.source_code_hash
      reserved_concurrent_executions = lambda.reserved_concurrent_executions
    }
  }
}

output "lambda_arns" {
  description = "Map of Lambda names to ARNs"
  value = {
    for name, lambda in aws_lambda_function.lambda : name => lambda.arn
  }
}

output "lambda_invoke_arns" {
  description = "Map of Lambda names to invoke ARNs"
  value = {
    for name, lambda in aws_lambda_function.lambda : name => lambda.invoke_arn
  }
}

output "lambda_function_names" {
  description = "Map of Lambda names to function names"
  value = {
    for name, lambda in aws_lambda_function.lambda : name => lambda.function_name
  }
}
