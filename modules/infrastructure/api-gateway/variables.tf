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
    stage_name                    = string
    log_retention_days            = number
    custom_domain = optional(object({
      domain_name     = string
      certificate_arn = string
    }))
    role_name = string
    policy_statements = list(object({
      sid       = string
      effect    = string
      actions   = list(string)
      resources = list(string)
    }))
  }))

  validation {
    condition = alltrue([
      for api in var.api_gateways : can(regex("^[A-Za-z0-9_-]{1,128}$", api.stage_name))
    ])
    error_message = "Stage names must be 1-128 letters, numbers, hyphens or underscores."
  }

  validation {
    condition = alltrue([
      for api in var.api_gateways : contains(
        [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
        api.log_retention_days
      )
    ])
    error_message = "log_retention_days must be a retention period CloudWatch accepts, such as 7, 14 or 30, or 0 to keep logs forever."
  }

  validation {
    condition = alltrue([
      for api in var.api_gateways : length(api.role_name) <= 64
    ])
    error_message = "API role names must be at most 64 characters."
  }

  validation {
    condition = alltrue(flatten([
      for api in var.api_gateways : [
        for statement in api.policy_statements :
        can(regex("^[A-Za-z0-9]+$", statement.sid)) && contains(["Allow", "Deny"], statement.effect)
      ]
    ]))
    error_message = "Policy statement SIDs must be alphanumeric, and effects must be Allow or Deny."
  }

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
