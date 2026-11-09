variable "iam_roles" {
  description = "List of IAM role configurations. See data module for structure."
  type = list(object({
    name      = string
    full_name = string
    path      = string
    assume_policy_principals = list(object({
      type        = string
      identifiers = list(string)
    }))
    policy_statements = list(object({
      sid       = string
      effect    = string
      actions   = list(string)
      resources = list(string)
    }))
  }))
}
