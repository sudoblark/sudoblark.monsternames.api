# Get current region
data "aws_region" "current_region" {}

# Retrieve the current AWS Account info
data "aws_caller_identity" "current_account" {}