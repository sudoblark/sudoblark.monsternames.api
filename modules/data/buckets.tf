/*
  S3 Buckets data structure definition:

  Each object requires:
  - name (string): Short name for the bucket (auto-prefixed with aws-sudoblark-production-monsternames-api)
  - versioning (bool): Whether versioning is enabled

  Optional fields:
  - folder_paths (list(string)): Folders to pre-create in the bucket (default: [])
  - days_retention (number): Days to retain objects before deletion (default: 365)
  - multipart_retention (number): Days to keep incomplete multipart uploads (default: 7)
  - enable_event_bridge (bool): Whether to enable EventBridge notifications (default: false)
  - log_bucket (string): Target bucket for access logs (default: null)

  Constraints:
  - Full bucket name (aws-sudoblark-production-monsternames-api-name) must be globally unique
  - Bucket names must be lowercase and use hyphens only

  Note:
  - All buckets use S3-managed encryption (AES-256) by default
  - KMS encryption disabled to reduce costs

  Example:
  {
    name             = "assets"
    versioning       = true
    folder_paths     = ["swagger_ui/"]
    days_retention   = 365
  }
*/

locals {
  buckets = [
    {
      name           = "assets"
      versioning     = true
      folder_paths   = ["swagger_ui/"]
      days_retention = 365
    }
  ]
}
