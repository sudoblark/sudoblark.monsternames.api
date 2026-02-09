output "roles" {
  description = "Map of created IAM roles with their attributes"
  value = {
    for name, role in aws_iam_role.role : name => {
      id                = role.id
      arn               = role.arn
      name              = role.name
      unique_id         = role.unique_id
      assume_role_policy = role.assume_role_policy
    }
  }
}

output "role_arns" {
  description = "Map of role names to ARNs"
  value = {
    for name, role in aws_iam_role.role : name => role.arn
  }
}

output "role_names" {
  description = "Map of role names to full names"
  value = {
    for name, role in aws_iam_role.role : name => role.name
  }
}
