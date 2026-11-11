# The module's input validation, with the AWS provider mocked. The module
# hashes zip_file_path at plan, so this file stands in for the package.

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  lambdas = [
    {
      name                           = "backend"
      function_name                  = "aws-sudoblark-production-monsternames-api-backend"
      description                    = "Retrieves monster names from DynamoDB"
      handler                        = "backend_lambda.main.handler"
      runtime                        = "python3.13"
      role_name                      = "aws-sudoblark-production-monsternames-api-backend"
      zip_file_path                  = "tests/validation.tftest.hcl"
      timeout                        = 29
      memory                         = 256
      environment_variables          = {}
      lambda_layers                  = []
      storage                        = 512
      reserved_concurrent_executions = -1
      security_group_ids             = []
      subnet_ids                     = []
      policy_statements = [
        {
          sid       = "AllowReadNameTables"
          effect    = "Allow"
          actions   = ["dynamodb:Scan"]
          resources = ["arn:aws:dynamodb:eu-west-2:123456789012:table/example"]
        }
      ]
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

run "rejects_a_role_name_over_64_characters" {
  command = plan

  variables {
    lambdas = [merge(var.lambdas[0], { role_name = join("", [for i in range(65) : "a"]) })]
  }

  expect_failures = [var.lambdas]
}

run "rejects_a_non_alphanumeric_sid" {
  command = plan

  variables {
    lambdas = [merge(var.lambdas[0], {
      policy_statements = [merge(var.lambdas[0].policy_statements[0], { sid = "Allow-Read" })]
    })]
  }

  expect_failures = [var.lambdas]
}

run "rejects_an_effect_other_than_allow_or_deny" {
  command = plan

  variables {
    lambdas = [merge(var.lambdas[0], {
      policy_statements = [merge(var.lambdas[0].policy_statements[0], { effect = "Permit" })]
    })]
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
