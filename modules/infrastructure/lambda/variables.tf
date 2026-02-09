variable "lambdas" {
  description = "List of Lambda function configurations. See data module for structure."
  type = list(object({
    account                        = string
    project                        = string
    application                    = string
    name                           = string
    full_name                      = string
    function_name                  = string
    arn                            = string
    description                    = string
    handler                        = string
    runtime                        = string
    role_arn                       = string
    zip_file_path                  = string
    timeout                        = number
    memory                         = number
    environment_variables          = map(string)
    lambda_layers                  = list(string)
    storage                        = number
    reserved_concurrent_executions = number
    security_group_ids             = list(string)
    subnet_ids                     = list(string)
  }))
}
