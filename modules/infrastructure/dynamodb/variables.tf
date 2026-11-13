variable "dynamodb_tables" {
  description = "List of DynamoDB table configurations. See data module for structure."
  type = list(object({
    name      = string
    full_name = string
    hash_key  = string
    items     = list(string)
  }))

  validation {
    condition = alltrue([
      for table in var.dynamodb_tables : can(regex("^[a-zA-Z0-9_.-]{3,255}$", table.full_name))
    ])
    error_message = "Table names must be 3-255 letters, numbers, underscores, hyphens and dots."
  }

  validation {
    condition = alltrue([
      for table in var.dynamodb_tables : length(distinct(table.items)) == length(table.items)
    ])
    error_message = "A table's seed items must be unique, because each item is keyed on its value."
  }
}
