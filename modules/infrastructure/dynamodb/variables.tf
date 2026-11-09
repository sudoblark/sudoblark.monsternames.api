variable "dynamodb_tables" {
  description = "List of DynamoDB table configurations. See data module for structure."
  type = list(object({
    name      = string
    full_name = string
    hash_key  = string
    items     = list(string)
  }))
}
