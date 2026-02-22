variable "buckets" {
  description = "List of S3 bucket configurations. See data module for structure."
  type = list(object({
    account             = string
    project             = string
    application         = string
    name                = string
    full_name           = string
    arn                 = string
    versioning          = bool
    folder_paths        = list(string)
    days_retention      = number
    multipart_retention = number
    enable_event_bridge = bool
    log_bucket          = optional(string)
    bucket_policy_json  = optional(string)
  }))
}
