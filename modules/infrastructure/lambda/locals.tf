locals {
  # Create a map for efficient lookups
  lambdas_map = {
    for lambda in var.lambdas : lambda.name => lambda
  }
}
