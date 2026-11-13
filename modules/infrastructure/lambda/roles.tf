# Each function's execution role: what its entry's policy_statements allow,
# plus writing to its own log group, which every function needs

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  for_each = local.lambdas_map

  name               = each.value.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name = each.value.role_name
  }
}

data "aws_iam_policy_document" "lambda" {
  for_each = local.lambdas_map

  # The function's own log group only. Terraform creates the group, so the
  # function never needs to.
  statement {
    sid    = "AllowWriteOwnLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.lambda_logs[each.key].arn}:*"]
  }

  dynamic "statement" {
    for_each = each.value.policy_statements
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role_policy" "lambda" {
  for_each = local.lambdas_map

  name   = "${each.value.role_name}-policy"
  role   = aws_iam_role.lambda[each.key].id
  policy = data.aws_iam_policy_document.lambda[each.key].json
}
