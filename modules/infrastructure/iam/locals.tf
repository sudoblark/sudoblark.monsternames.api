locals {
  # Create a map for efficient lookups
  iam_roles_map = {
    for role in var.iam_roles : role.name => role
  }
}
