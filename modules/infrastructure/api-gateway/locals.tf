locals {
  # Create a map for efficient lookups
  api_gateways_map = {
    for api in var.api_gateways : api.name => api
  }

  # One JSON line per request in each stage's access log. Headers, query
  # strings and bodies are left out, so no caller's data reaches the log.
  access_log_format = jsonencode({
    requestId      = "$context.requestId"
    ip             = "$context.identity.sourceIp"
    requestTime    = "$context.requestTime"
    httpMethod     = "$context.httpMethod"
    path           = "$context.path"
    status         = "$context.status"
    protocol       = "$context.protocol"
    responseLength = "$context.responseLength"
  })

  # APIs whose integrations need a role, such as to read from S3
  integration_roles_map = {
    for name, api in local.api_gateways_map : name => api
    if length(api.policy_statements) > 0
  }

  # Flatten Lambda permissions for all APIs
  lambda_permissions = flatten([
    for api in var.api_gateways : [
      for function_name in api.allowed_lambda_function_names : {
        api_name      = api.name
        function_name = function_name
        key           = "${api.name}-${function_name}"
      }
    ]
  ])

  lambda_permissions_map = {
    for perm in local.lambda_permissions : perm.key => perm
  }

  # Flatten API keys for all APIs
  api_keys_flat = flatten([
    for api in var.api_gateways : [
      for key_name in api.api_keys : {
        api_name = api.name
        key_name = key_name
        key      = "${api.name}-${key_name}"
      }
    ]
  ])

  api_keys_map = {
    for key in local.api_keys_flat : key.key => key
  }
}
