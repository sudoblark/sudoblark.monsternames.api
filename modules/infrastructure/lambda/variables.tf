variable "lambdas" {
  description = "List of Lambda function configurations. See data module for structure."
  type = list(object({
    name                           = string
    function_name                  = string
    description                    = string
    handler                        = string
    runtime                        = string
    role_name                      = string
    zip_file_path                  = string
    timeout                        = number
    memory                         = number
    environment_variables          = map(string)
    lambda_layers                  = list(string)
    storage                        = number
    reserved_concurrent_executions = number
    security_group_ids             = list(string)
    subnet_ids                     = list(string)
    policy_statements = list(object({
      sid       = string
      effect    = string
      actions   = list(string)
      resources = list(string)
    }))
  }))

  validation {
    condition = alltrue([
      for lambda in var.lambdas : length(lambda.function_name) <= 64
    ])
    error_message = "Lambda function names must be at most 64 characters."
  }

  validation {
    condition = alltrue([
      for lambda in var.lambdas : length(lambda.role_name) <= 64
    ])
    error_message = "Lambda role names must be at most 64 characters."
  }

  validation {
    condition = alltrue(flatten([
      for lambda in var.lambdas : [
        for statement in lambda.policy_statements :
        can(regex("^[A-Za-z0-9]+$", statement.sid)) && contains(["Allow", "Deny"], statement.effect)
      ]
    ]))
    error_message = "Policy statement SIDs must be alphanumeric, and effects must be Allow or Deny."
  }

  validation {
    condition = alltrue([
      for lambda in var.lambdas : lambda.timeout >= 1 && lambda.timeout <= 900
    ])
    error_message = "Lambda timeouts must be between 1 and 900 seconds."
  }

  validation {
    condition = alltrue([
      for lambda in var.lambdas :
      lambda.memory >= 128 && lambda.memory <= 10240 && lambda.storage >= 512 && lambda.storage <= 10240
    ])
    error_message = "Lambda memory must be 128-10240 MB, and ephemeral storage 512-10240 MB."
  }

  validation {
    condition = alltrue([
      for lambda in var.lambdas : lambda.reserved_concurrent_executions >= -1
    ])
    error_message = "reserved_concurrent_executions must be -1 (unreserved) or more."
  }
}
