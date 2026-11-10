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

  validation {
    condition = alltrue([
      for role in var.iam_roles : length(role.full_name) <= 64
    ])
    error_message = "Role names must be at most 64 characters."
  }

  validation {
    condition = alltrue([
      for role in var.iam_roles : can(regex("^/(.*/)?$", role.path))
    ])
    error_message = "Role paths must start and end with \"/\"."
  }

  validation {
    condition = alltrue(flatten([
      for role in var.iam_roles : [
        for statement in role.policy_statements :
        can(regex("^[A-Za-z0-9]+$", statement.sid)) && contains(["Allow", "Deny"], statement.effect)
      ]
    ]))
    error_message = "Policy statement SIDs must be alphanumeric, and effects must be Allow or Deny."
  }
}
