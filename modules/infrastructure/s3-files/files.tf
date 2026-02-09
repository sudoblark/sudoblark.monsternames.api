# Regular file uploads (no templating)
resource "aws_s3_object" "files" {
  for_each = local.regular_files

  bucket        = each.value.bucket_id
  key           = each.value.object_key
  source        = each.value.source_path
  content_type  = each.value.content_type
  etag          = filemd5(each.value.source_path)

  tags = {
    Name = each.value.name
  }
}

# Templated file uploads
resource "aws_s3_object" "templated_files" {
  for_each = local.templated_files

  bucket       = each.value.bucket_id
  key          = each.value.object_key
  content      = templatefile(each.value.source_path, each.value.template_variables)
  content_type = each.value.content_type
  etag         = md5(templatefile(each.value.source_path, each.value.template_variables))

  tags = {
    Name = each.value.name
  }
}
