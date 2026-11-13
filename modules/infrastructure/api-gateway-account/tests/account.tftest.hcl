# API Gateway's account-wide settings, with the AWS provider mocked. Mock
# values are used at plan, so the role's ARN is known when the account is set.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/aws-sudoblark-production-api-gateway-cloudwatch"
    }
  }
}

variables {
  api_gateway_account = {
    cloudwatch_role_name = "aws-sudoblark-production-api-gateway-cloudwatch"
  }
}

run "the_account_logs_through_its_own_role" {
  command = plan

  assert {
    condition     = aws_iam_role.cloudwatch.name == "aws-sudoblark-production-api-gateway-cloudwatch"
    error_message = "The CloudWatch role must take the name the data gives."
  }

  assert {
    condition     = aws_api_gateway_account.account.cloudwatch_role_arn == aws_iam_role.cloudwatch.arn
    error_message = "The account's API Gateway settings must name the module's CloudWatch role."
  }

  assert {
    condition     = one(data.aws_iam_policy_document.assume_role.statement[0].principals).identifiers == toset(["apigateway.amazonaws.com"])
    error_message = "Only API Gateway may assume the CloudWatch role."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.cloudwatch.policy_arn == "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
    error_message = "The CloudWatch role must be able to write API Gateway's logs."
  }
}

run "rejects_a_role_name_over_64_characters" {
  command = plan

  variables {
    api_gateway_account = {
      cloudwatch_role_name = join("", [for i in range(65) : "a"])
    }
  }

  expect_failures = [var.api_gateway_account]
}
