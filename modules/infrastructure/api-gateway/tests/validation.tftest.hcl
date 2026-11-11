# The module's input validation, with the AWS provider mocked.

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

run "accepts_a_valid_api" {
  command = plan
}

run "rejects_an_unknown_quota_period" {
  command = plan

  variables {
    api_gateways = [merge(var.api_gateways[0], { quota_period = "YEAR" })]
  }

  expect_failures = [var.api_gateways]
}

run "rejects_a_zero_rate_limit" {
  command = plan

  variables {
    api_gateways = [merge(var.api_gateways[0], { rate_limit = 0 })]
  }

  expect_failures = [var.api_gateways]
}

run "rejects_a_negative_burst_limit" {
  command = plan

  variables {
    api_gateways = [merge(var.api_gateways[0], { burst_limit = -1 })]
  }

  expect_failures = [var.api_gateways]
}

run "rejects_a_role_name_over_64_characters" {
  command = plan

  variables {
    api_gateways = [merge(var.api_gateways[0], { role_name = join("", [for i in range(65) : "a"]) })]
  }

  expect_failures = [var.api_gateways]
}

run "rejects_a_non_alphanumeric_sid" {
  command = plan

  variables {
    api_gateways = [merge(var.api_gateways[0], {
      policy_statements = [merge(var.api_gateways[0].policy_statements[0], { sid = "Allow-Get" })]
    })]
  }

  expect_failures = [var.api_gateways]
}

run "rejects_an_effect_other_than_allow_or_deny" {
  command = plan

  variables {
    api_gateways = [merge(var.api_gateways[0], {
      policy_statements = [merge(var.api_gateways[0].policy_statements[0], { effect = "Permit" })]
    })]
  }

  expect_failures = [var.api_gateways]
}
