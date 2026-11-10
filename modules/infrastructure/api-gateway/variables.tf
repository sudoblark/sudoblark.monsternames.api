variable "api_gateways" {
  description = "List of API Gateway configurations. See data module for structure."
  type = list(object({
    name                          = string
    full_name                     = string
    description                   = string
    openapi_spec_path             = string
    template_variables            = map(string)
    allowed_lambda_function_names = list(string)
    quota_limit                   = number
    quota_offset                  = number
    quota_period                  = string
    burst_limit                   = number
    rate_limit                    = number
    api_keys                      = list(string)
    custom_domain = optional(object({
      domain_name     = string
      certificate_arn = string
    }))
  }))

  validation {
    condition = alltrue([
      for api in var.api_gateways : contains(["DAY", "WEEK", "MONTH"], api.quota_period)
    ])
    error_message = "quota_period must be DAY, WEEK or MONTH."
  }

  validation {
    condition = alltrue([
      for api in var.api_gateways : api.rate_limit > 0 && api.burst_limit >= 0
    ])
    error_message = "rate_limit must be positive, and burst_limit zero or more."
  }
}

variable "dns_zone_id" {
  description = "Route53 hosted zone ID for DNS record creation"
  type        = string
}
