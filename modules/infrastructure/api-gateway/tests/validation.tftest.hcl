# The module's input validation, with the AWS provider mocked.

mock_provider "aws" {}

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
