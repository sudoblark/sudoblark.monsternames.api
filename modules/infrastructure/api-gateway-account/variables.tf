variable "api_gateway_account" {
  description = "API Gateway's account-wide settings. See data module for structure."
  type = object({
    cloudwatch_role_name = string
  })

  validation {
    condition     = length(var.api_gateway_account.cloudwatch_role_name) <= 64
    error_message = "The CloudWatch role name must be at most 64 characters."
  }
}
