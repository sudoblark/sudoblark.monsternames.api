resource "aws_api_gateway_rest_api" "api" {
  for_each = local.api_gateways_map

  name        = each.value.full_name
  description = each.value.description

  body = templatefile(each.value.openapi_spec_path, each.value.template_variables)

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = each.value.full_name
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  for_each = local.api_gateways_map

  rest_api_id = aws_api_gateway_rest_api.api[each.key].id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.api[each.key].body,
      aws_api_gateway_rest_api.api[each.key].id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "production" {
  for_each = local.api_gateways_map

  deployment_id = aws_api_gateway_deployment.deployment[each.key].id
  rest_api_id   = aws_api_gateway_rest_api.api[each.key].id
  stage_name    = "production"

  tags = {
    Name = "${each.value.full_name}-production"
  }
}

resource "aws_api_gateway_usage_plan" "plan" {
  for_each = local.api_gateways_map

  name        = "${each.value.full_name}-plan"
  description = "Usage plan for ${each.value.full_name}"

  api_stages {
    api_id = aws_api_gateway_rest_api.api[each.key].id
    stage  = aws_api_gateway_stage.production[each.key].stage_name
  }

  quota_settings {
    limit  = each.value.quota_limit
    offset = each.value.quota_offset
    period = each.value.quota_period
  }

  throttle_settings {
    burst_limit = each.value.burst_limit
    rate_limit  = each.value.rate_limit
  }

  tags = {
    Name = "${each.value.full_name}-plan"
  }
}

resource "aws_api_gateway_api_key" "keys" {
  for_each = local.api_keys_map

  name        = "${local.api_gateways_map[each.value.api_name].full_name}-${each.value.key_name}"
  description = "API key for ${local.api_gateways_map[each.value.api_name].full_name}"
  enabled     = true

  tags = {
    Name = "${local.api_gateways_map[each.value.api_name].full_name}-${each.value.key_name}"
  }
}

resource "aws_api_gateway_usage_plan_key" "plan_key" {
  for_each = local.api_keys_map

  key_id        = aws_api_gateway_api_key.keys[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.plan[each.value.api_name].id
}

# Lambda permissions to allow API Gateway to invoke
resource "aws_lambda_permission" "api_gateway" {
  for_each = local.lambda_permissions_map

  statement_id  = "AllowExecutionFromAPIGateway-${each.value.api_name}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api[each.value.api_name].execution_arn}/*/*/*"
}

# CloudWatch Logs for API Gateway
resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "api-gateway-cloudwatch-global"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_method_settings" "settings" {
  for_each = local.api_gateways_map

  rest_api_id = aws_api_gateway_rest_api.api[each.key].id
  stage_name  = aws_api_gateway_stage.production[each.key].stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = false
  }
}
