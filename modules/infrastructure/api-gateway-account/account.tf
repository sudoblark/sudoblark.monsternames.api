# API Gateway's settings for this account and region, which every API in it
# shares: the role API Gateway assumes to write execution logs to CloudWatch

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudwatch" {
  name               = var.api_gateway_account.cloudwatch_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name = var.api_gateway_account.cloudwatch_role_name
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn

  # API Gateway checks the role can write to CloudWatch when it's set
  depends_on = [aws_iam_role_policy_attachment.cloudwatch]
}
