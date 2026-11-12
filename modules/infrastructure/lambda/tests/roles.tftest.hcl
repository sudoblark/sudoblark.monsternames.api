# The IAM role each function gets, with the AWS provider mocked. Mock values
# are used at plan, so the log group's ARN is known when the policy is built.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:eu-west-2:123456789012:log-group:/aws/lambda/aws-sudoblark-production-monsternames-api-backend"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/aws-sudoblark-production-monsternames-api-backend"
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
      zip_file_path                  = "tests/roles.tftest.hcl"
      timeout                        = 29
      memory                         = 256
      environment_variables          = {}
      lambda_layers                  = []
      storage                        = 512
      reserved_concurrent_executions = -1
      security_group_ids             = []
      subnet_ids                     = []
      log_retention_days             = 30
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

run "each_function_runs_as_its_own_role" {
  command = plan

  assert {
    condition     = aws_iam_role.lambda["backend"].name == "aws-sudoblark-production-monsternames-api-backend"
    error_message = "Each function's role must take the role_name its data entry gives."
  }

  assert {
    condition     = aws_lambda_function.lambda["backend"].role == aws_iam_role.lambda["backend"].arn
    error_message = "Each function must run as its own role."
  }
}

run "a_function_writes_only_its_own_logs" {
  command = plan

  assert {
    condition     = data.aws_iam_policy_document.lambda["backend"].statement[0].resources == toset(["arn:aws:logs:eu-west-2:123456789012:log-group:/aws/lambda/aws-sudoblark-production-monsternames-api-backend:*"])
    error_message = "A function may only write to its own log group."
  }

  assert {
    condition     = data.aws_iam_policy_document.lambda["backend"].statement[0].actions == toset(["logs:CreateLogStream", "logs:PutLogEvents"])
    error_message = "A function must not create log groups, since Terraform creates its own."
  }
}

run "a_function_gets_its_entrys_statements" {
  command = plan

  assert {
    condition = (
      data.aws_iam_policy_document.lambda["backend"].statement[1].sid == "AllowReadNameTables" &&
      data.aws_iam_policy_document.lambda["backend"].statement[1].actions == toset(["dynamodb:Scan"]) &&
      data.aws_iam_policy_document.lambda["backend"].statement[1].resources == toset(["arn:aws:dynamodb:eu-west-2:123456789012:table/example"])
    )
    error_message = "A function's role must allow what its entry's policy_statements give."
  }
}
