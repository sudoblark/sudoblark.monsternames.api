locals {
  # Create a map for efficient lookups
  lambdas_map = {
    for lambda in var.lambdas : lambda.name => lambda
  }

  # Separate lambdas with and without VPC config
  lambdas_with_vpc = {
    for k, v in local.lambdas_map : k => v
    if length(v.subnet_ids) > 0
  }

  lambdas_without_vpc = {
    for k, v in local.lambdas_map : k => v
    if length(v.subnet_ids) == 0
  }
}
