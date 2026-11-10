# The module's input validation, with the AWS provider mocked. The module
# hashes source_path at plan, so this file stands in for the upload.

mock_provider "aws" {}

variables {
  s3_files = [
    {
      name               = "swagger-ui"
      source_path        = "tests/validation.tftest.hcl"
      bucket_id          = "aws-sudoblark-production-monsternames-api-assets"
      object_key         = "swagger_ui/index.html"
      content_type       = "text/html"
      template_variables = {}
    }
  ]
}

run "accepts_a_valid_file" {
  command = plan
}

run "rejects_a_key_with_a_leading_slash" {
  command = plan

  variables {
    s3_files = [merge(var.s3_files[0], { object_key = "/swagger_ui/index.html" })]
  }

  expect_failures = [var.s3_files]
}
