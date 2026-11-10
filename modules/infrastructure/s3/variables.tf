variable "buckets" {
  description = "List of S3 bucket configurations. See data module for structure."
  type = list(object({
    name                = string
    full_name           = string
    versioning          = bool
    folder_paths        = list(string)
    days_retention      = optional(number)
    multipart_retention = number
    enable_event_bridge = bool
    log_bucket          = optional(string)
    bucket_policy_json  = optional(string)
  }))

  validation {
    condition = alltrue([
      for bucket in var.buckets : can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", bucket.full_name))
    ])
    error_message = "Bucket names must be 3-63 lowercase letters, numbers, dots and hyphens, starting and ending with a letter or number."
  }

  validation {
    condition = alltrue([
      for bucket in var.buckets : coalesce(bucket.days_retention, 1) > 0 && bucket.multipart_retention > 0
    ])
    error_message = "days_retention, when set, and multipart_retention must be at least one day."
  }

  validation {
    condition = alltrue(flatten([
      for bucket in var.buckets : [for path in bucket.folder_paths : endswith(path, "/")]
    ]))
    error_message = "folder_paths must end with \"/\"."
  }
}
