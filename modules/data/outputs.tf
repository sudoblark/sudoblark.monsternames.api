output "buckets" {
  description = "List of enriched S3 bucket configurations"
  value       = local.buckets_enriched
}

output "buckets_map" {
  description = "Map of S3 buckets keyed by short name"
  value       = local.buckets_map
}

output "iam_roles" {
  description = "List of enriched IAM role configurations"
  value       = local.iam_roles_enriched
}

output "iam_roles_map" {
  description = "Map of IAM roles keyed by short name"
  value       = local.iam_roles_map
}

output "lambdas" {
  description = "List of enriched Lambda function configurations"
  value       = local.lambdas_enriched
}

output "lambdas_map" {
  description = "Map of Lambda functions keyed by short name"
  value       = local.lambdas_map
}

output "api_gateways" {
  description = "List of enriched API Gateway configurations"
  value       = local.api_gateways_enriched
}

output "api_gateways_map" {
  description = "Map of API Gateways keyed by short name"
  value       = local.api_gateways_map
}

output "s3_files" {
  description = "List of enriched S3 file configurations"
  value       = local.s3_files_enriched
}

output "s3_files_map" {
  description = "Map of S3 files keyed by short name"
  value       = local.s3_files_map
}

output "defaults" {
  description = "Default values used across infrastructure"
  value = {
    account         = local.account
    project         = local.project
    application     = local.application
    region          = local.region
    account_id      = local.account_id
    resource_prefix = local.resource_prefix
    default_tags    = local.default_tags
  }
}
