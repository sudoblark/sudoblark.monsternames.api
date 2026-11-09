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
}
