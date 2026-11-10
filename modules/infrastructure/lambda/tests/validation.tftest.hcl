# The module's input validation, with the AWS provider mocked. The module
# hashes zip_file_path at plan, so this file stands in for the package.

mock_provider "aws" {}

variables {
  lambdas = [
    {
      name                           = "backend"
      function_name                  = "aws-sudoblark-production-monsternames-api-backend"
      description                    = "Retrieves monster names from DynamoDB"
      handler                        = "backend_lambda.main.handler"
      runtime                        = "python3.11"
      role_arn                       = "arn:aws:iam::123456789012:role/example"
      zip_file_path                  = "tests/validation.tftest.hcl"
      timeout                        = 29
      memory                         = 256
      environment_variables          = {}
      lambda_layers                  = []
      storage                        = 512
      reserved_concurrent_executions = -1
      security_group_ids             = []
      subnet_ids                     = []
    }
  ]
}

run "accepts_a_valid_lambda" {
  command = plan
}

run "rejects_a_name_over_64_characters" {
  command = plan

  variables {
    lambdas = [merge(var.lambdas[0], { function_name = join("", [for i in range(65) : "a"]) })]
  }

  expect_failures = [var.lambdas]
}

run "rejects_a_timeout_over_900_seconds" {
  command = plan

  variables {
    lambdas = [merge(var.lambdas[0], { timeout = 901 })]
  }

  expect_failures = [var.lambdas]
}

run "rejects_memory_under_128_mb" {
  command = plan

  variables {
    lambdas = [merge(var.lambdas[0], { memory = 64 })]
  }

  expect_failures = [var.lambdas]
}

run "rejects_reserved_concurrency_under_minus_one" {
  command = plan

  variables {
    lambdas = [merge(var.lambdas[0], { reserved_concurrent_executions = -2 })]
  }

  expect_failures = [var.lambdas]
}
