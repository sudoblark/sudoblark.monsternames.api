variable "account" {
  description = "The AWS account this environment root deploys to, one of the accounts in defaults.tf"
  type        = string

  validation {
    condition     = contains(keys(local.accounts), var.account)
    error_message = "account must be one of the accounts in defaults.tf."
  }
}

variable "dns_zone_id" {
  description = "Route53 hosted zone ID from DNS infrastructure"
  type        = string
}

variable "dns_certificate_arn_regional" {
  description = "Regional ACM certificate ARN from DNS infrastructure"
  type        = string
}
