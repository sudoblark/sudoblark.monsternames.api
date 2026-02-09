resource "aws_s3_bucket" "bucket" {
  for_each = local.buckets_map

  bucket = each.value.full_name

  tags = {
    Name = each.value.full_name
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  for_each = local.buckets_map

  bucket = aws_s3_bucket.bucket[each.key].id

  versioning_configuration {
    status = each.value.versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  for_each = local.buckets_map

  bucket = aws_s3_bucket.bucket[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  for_each = local.buckets_map

  bucket = aws_s3_bucket.bucket[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  for_each = local.buckets_map

  bucket = aws_s3_bucket.bucket[each.key].id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    expiration {
      days = each.value.days_retention
    }

    noncurrent_version_expiration {
      noncurrent_days = each.value.days_retention
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = each.value.multipart_retention
    }
  }
}

resource "aws_s3_bucket_logging" "logging" {
  for_each = {
    for k, v in local.buckets_map : k => v if v.log_bucket != null
  }

  bucket = aws_s3_bucket.bucket[each.key].id

  target_bucket = each.value.log_bucket
  target_prefix = "${each.value.full_name}/"
}

resource "aws_s3_bucket_notification" "eventbridge" {
  for_each = {
    for k, v in local.buckets_map : k => v if v.enable_event_bridge
  }

  bucket      = aws_s3_bucket.bucket[each.key].id
  eventbridge = true
}

resource "aws_s3_bucket_policy" "policy" {
  for_each = {
    for k, v in local.buckets_map : k => v if v.bucket_policy_json != null
  }

  bucket = aws_s3_bucket.bucket[each.key].id
  policy = each.value.bucket_policy_json
}

# Create folder structure (zero-byte objects with trailing slash)
resource "aws_s3_object" "folders" {
  for_each = local.folders_map

  bucket       = each.value.bucket_name
  key          = each.value.folder_path
  content      = ""
  content_type = "application/x-directory"

  depends_on = [aws_s3_bucket.bucket]
}
