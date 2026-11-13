variable "s3_files" {
  description = "List of S3 file configurations. See data module for structure."
  type = list(object({
    name               = string
    source_path        = string
    bucket_id          = string
    object_key         = string
    content_type       = optional(string)
    template_variables = map(string)
  }))

  validation {
    condition = alltrue([
      for file in var.s3_files : !startswith(file.object_key, "/")
    ])
    error_message = "object_key must not start with \"/\"."
  }
}
