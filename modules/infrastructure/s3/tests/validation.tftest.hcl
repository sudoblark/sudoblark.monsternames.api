# The module's input validation, with the AWS provider mocked.

mock_provider "aws" {}

variables {
  buckets = [
    {
      name                = "assets"
      full_name           = "aws-sudoblark-production-monsternames-api-assets"
      versioning          = false
      folder_paths        = ["swagger_ui/"]
      days_retention      = null
      multipart_retention = 7
      enable_event_bridge = false
    }
  ]
}

run "accepts_a_valid_bucket" {
  command = plan
}

run "rejects_an_invalid_name" {
  command = plan

  variables {
    buckets = [merge(var.buckets[0], { full_name = "Not_A_Bucket_Name" })]
  }

  expect_failures = [var.buckets]
}

run "rejects_a_zero_day_retention" {
  command = plan

  variables {
    buckets = [merge(var.buckets[0], { days_retention = 0 })]
  }

  expect_failures = [var.buckets]
}

run "rejects_a_folder_without_a_trailing_slash" {
  command = plan

  variables {
    buckets = [merge(var.buckets[0], { folder_paths = ["swagger_ui"] })]
  }

  expect_failures = [var.buckets]
}
