resource "aws_lambda_function" "lambda" {
  for_each = local.lambdas_map

  filename         = each.value.zip_file_path
  function_name    = each.value.function_name
  role             = each.value.role_arn
  handler          = each.value.handler
  runtime          = each.value.runtime
  timeout          = each.value.timeout
  memory_size      = each.value.memory
  source_code_hash = filebase64sha256(each.value.zip_file_path)
  description      = each.value.description
  layers           = each.value.lambda_layers

  reserved_concurrent_executions = each.value.reserved_concurrent_executions

  environment {
    variables = each.value.environment_variables
  }

  ephemeral_storage {
    size = each.value.storage
  }

  dynamic "vpc_config" {
    for_each = length(each.value.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = each.value.subnet_ids
      security_group_ids = each.value.security_group_ids
    }
  }

  tags = {
    Name = each.value.function_name
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.lambdas_map

  name              = "/aws/lambda/${each.value.function_name}"
  retention_in_days = 14

  tags = {
    Name = "${each.value.function_name}-logs"
  }
}
