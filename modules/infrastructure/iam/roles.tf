data "aws_iam_policy_document" "assume_role" {
  for_each = local.iam_roles_map

  dynamic "statement" {
    for_each = each.value.assume_policy_principals
    content {
      effect = "Allow"
      principals {
        type        = statement.value.type
        identifiers = statement.value.identifiers
      }
      actions = ["sts:AssumeRole"]
    }
  }
}

resource "aws_iam_role" "role" {
  for_each = local.iam_roles_map

  name               = each.value.full_name
  path               = each.value.path
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json

  tags = {
    Name = each.value.full_name
  }
}

data "aws_iam_policy_document" "role_policy" {
  for_each = local.iam_roles_map

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

resource "aws_iam_role_policy" "policy" {
  for_each = local.iam_roles_map

  name   = "${each.value.full_name}-policy"
  role   = aws_iam_role.role[each.key].id
  policy = data.aws_iam_policy_document.role_policy[each.key].json
}
