# The module's input validation, with the AWS provider mocked.

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  iam_roles = [
    {
      name      = "backend-lambda"
      full_name = "aws-sudoblark-production-monsternames-api-backend-lambda"
      path      = "/"
      assume_policy_principals = [
        {
          type        = "Service"
          identifiers = ["lambda.amazonaws.com"]
        }
      ]
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

run "accepts_a_valid_role" {
  command = plan
}

run "rejects_a_name_over_64_characters" {
  command = plan

  variables {
    iam_roles = [merge(var.iam_roles[0], { full_name = join("", [for i in range(65) : "a"]) })]
  }

  expect_failures = [var.iam_roles]
}

run "rejects_a_path_without_slashes" {
  command = plan

  variables {
    iam_roles = [merge(var.iam_roles[0], { path = "service-role" })]
  }

  expect_failures = [var.iam_roles]
}

run "rejects_a_non_alphanumeric_sid" {
  command = plan

  variables {
    iam_roles = [merge(var.iam_roles[0], {
      policy_statements = [merge(var.iam_roles[0].policy_statements[0], { sid = "Allow-Read" })]
    })]
  }

  expect_failures = [var.iam_roles]
}

run "rejects_an_unknown_effect" {
  command = plan

  variables {
    iam_roles = [merge(var.iam_roles[0], {
      policy_statements = [merge(var.iam_roles[0].policy_statements[0], { effect = "Permit" })]
    })]
  }

  expect_failures = [var.iam_roles]
}
