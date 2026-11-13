# The role each API's integrations assume, with what its entry's
# policy_statements allow. The spec names it as their credentials.

data "aws_iam_policy_document" "integrations_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "integrations" {
  for_each = local.integration_roles_map

  name               = each.value.role_name
  assume_role_policy = data.aws_iam_policy_document.integrations_assume_role.json

  tags = {
    Name = each.value.role_name
  }
}

data "aws_iam_policy_document" "integrations" {
  for_each = local.integration_roles_map

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

resource "aws_iam_role_policy" "integrations" {
  for_each = local.integration_roles_map

  name   = "${each.value.role_name}-policy"
  role   = aws_iam_role.integrations[each.key].id
  policy = data.aws_iam_policy_document.integrations[each.key].json
}
