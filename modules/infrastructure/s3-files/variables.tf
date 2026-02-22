variable "s3_files" {
  description = "List of S3 file configurations. See data module for structure."
  type = list(object({
    account            = string
    project            = string
    application        = string
    name               = string
    source_path        = string
    bucket_name        = string
    bucket_id          = string
    bucket_arn         = string
    object_key         = string
    content_type       = optional(string)
    template_variables = map(string)
  }))
}
