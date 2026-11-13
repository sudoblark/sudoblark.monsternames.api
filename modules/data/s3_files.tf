/*
  S3 Files data structure definition:

  Each object requires:
  - name (string): Friendly name for Terraform resource identification
  - source_path (string): Local path to the file to upload
  - bucket_name (string): Target bucket name (references buckets by short name)
  - object_key (string): S3 object key (path in bucket)

  Optional fields:
  - content_type (string): MIME type of the file (default: auto-detected)
  - template_variables (map(string)): Variables for templating (default: {})

  Constraints:
  - source_path must exist and be readable
  - bucket_name must reference an existing bucket in buckets.tf
  - object_key must not start with "/", which the s3-files module enforces

  Bucket References (resolved in infrastructure.tf):
  - Bucket names → Full bucket IDs and ARNs

  Example:
  {
    name         = "swagger-ui"
    source_path  = "./application/swagger_ui/index.html"
    bucket_name  = "assets"       # Resolved to full bucket name
    object_key   = "swagger_ui/index.html"
    content_type = "text/html"
  }
*/

locals {
  s3_files = [
    {
      name         = "swagger-ui"
      source_path  = "../../application/swagger_ui/index.html"
      bucket_name  = "assets"
      object_key   = "swagger_ui/index.html"
      content_type = "text/html"
    },
    {
      name         = "openapi-spec"
      source_path  = "../../application/open_api_definitions/monsternames.yaml"
      bucket_name  = "assets"
      object_key   = "open_api_definitions/monsternames.yaml"
      content_type = "application/x-yaml"

      # The API's spec without its integration blocks, so no ARNs are
      # published. The template needs every variable, so this takes the
      # API's own, but the integration ones are never rendered here.
      template_variables = merge(local.api_gateways_map["backend"].template_variables, {
        include_integrations = "false"
      })
    }
  ]
}
