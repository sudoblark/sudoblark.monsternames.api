output "uploaded_files" {
  description = "Map of uploaded S3 objects"
  value = merge(
    {
      for name, obj in aws_s3_object.files : name => {
        id           = obj.id
        key          = obj.key
        bucket       = obj.bucket
        etag         = obj.etag
        version_id   = obj.version_id
      }
    },
    {
      for name, obj in aws_s3_object.templated_files : name => {
        id           = obj.id
        key          = obj.key
        bucket       = obj.bucket
        etag         = obj.etag
        version_id   = obj.version_id
      }
    }
  )
}
