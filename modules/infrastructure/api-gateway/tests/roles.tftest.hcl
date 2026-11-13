# The IAM role each API's integrations assume, with the AWS provider mocked.

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  dns_zone_id = "Z0123456789TESTZONE"

  api_gateways = [
    {
      name                          = "backend"
      full_name                     = "aws-sudoblark-production-monsternames-api-backend"
      description                   = "Test API"
      openapi_spec_path             = "tests/openapi.yaml"
      template_variables            = {}
      allowed_lambda_function_names = []
      quota_limit                   = 10
      quota_offset                  = 0
      quota_period                  = "DAY"
      burst_limit                   = 5
      rate_limit                    = 100
      api_keys                      = []
      stage_name                    = "production"
      log_retention_days            = 30
      role_name                     = "aws-sudoblark-production-monsternames-api-backend-integrations"
      policy_statements = [
        {
          sid       = "AllowGetObjectAssetsBucket"
          effect    = "Allow"
          actions   = ["s3:GetObject"]
          resources = ["arn:aws:s3:::example/*"]
        }
      ]
    }
  ]
}

run "an_api_with_statements_gets_its_own_role" {
  command = plan

  assert {
    condition     = aws_iam_role.integrations["backend"].name == "aws-sudoblark-production-monsternames-api-backend-integrations"
    error_message = "An API's role must take the role_name its data entry gives."
  }

  assert {
    condition     = one(data.aws_iam_policy_document.integrations_assume_role.statement[0].principals).identifiers == toset(["apigateway.amazonaws.com"])
    error_message = "Only API Gateway may assume an API's integrations role."
  }

  assert {
    condition = (
      data.aws_iam_policy_document.integrations["backend"].statement[0].sid == "AllowGetObjectAssetsBucket" &&
      data.aws_iam_policy_document.integrations["backend"].statement[0].actions == toset(["s3:GetObject"]) &&
      data.aws_iam_policy_document.integrations["backend"].statement[0].resources == toset(["arn:aws:s3:::example/*"])
    )
    error_message = "An API's role must allow what its entry's policy_statements give."
  }
}

run "an_api_without_statements_gets_no_role" {
  command = plan

  variables {
    api_gateways = [merge(var.api_gateways[0], { policy_statements = [] })]
  }

  assert {
    condition     = length(aws_iam_role.integrations) == 0
    error_message = "An API with no policy_statements must get no role."
  }
}
