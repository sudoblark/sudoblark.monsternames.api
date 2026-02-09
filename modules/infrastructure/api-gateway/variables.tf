variable "api_gateways" {
  description = "List of API Gateway configurations. See data module for structure."
  type = list(object({
    account                       = string
    project                       = string
    application                   = string
    name                          = string
    full_name                     = string
    description                   = string
    openapi_spec_path             = string
    template_variables            = map(string)
    allowed_lambda_arns           = list(string)
    allowed_lambda_function_names = list(string)
    quota_limit                   = number
    quota_offset                  = number
    quota_period                  = string
    burst_limit                   = number
    rate_limit                    = number
    api_keys                      = list(string)
  }))
}
