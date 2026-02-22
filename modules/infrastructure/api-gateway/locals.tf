locals {
  # Create a map for efficient lookups
  api_gateways_map = {
    for api in var.api_gateways : api.name => api
  }

  # Flatten Lambda permissions for all APIs
  lambda_permissions = flatten([
    for api in var.api_gateways : [
      for idx, lambda_arn in api.allowed_lambda_arns : {
        api_name      = api.name
        lambda_arn    = lambda_arn
        function_name = api.allowed_lambda_function_names[idx]
        key           = "${api.name}-${api.allowed_lambda_function_names[idx]}"
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
