/*
  Infrastructure enrichment and cross-reference resolution.
  
  This file takes the raw data structures from individual service files
  and enriches them with:
  - Default values
  - Computed values (ARNs, full names)
  - Cross-references between resources
  - Lookup maps for efficient referencing
*/

# ============================================================================
# S3 Buckets Enrichment
# ============================================================================

locals {
  # Enrich bucket data with computed values
  buckets_enriched = [
    for bucket in local.buckets : merge(
      {
        # Defaults
        folder_paths        = []
        days_retention      = null
        multipart_retention = 7
        enable_event_bridge = false
        log_bucket          = null
        bucket_policy_json  = null
      },
      bucket,
      {
        # Computed values
        full_name = lower("${local.resource_prefix}-${bucket.name}")
        arn       = "arn:aws:s3:::${lower("${local.resource_prefix}-${bucket.name}")}"
      }
    )
  ]

  # Create lookup map for cross-referencing
  buckets_map = {
    for bucket in local.buckets_enriched : bucket.name => bucket
  }
}

# ============================================================================
# DynamoDB Tables Enrichment
# ============================================================================

locals {
  # Enrich DynamoDB table data with computed values and seed items
  dynamodb_tables_enriched = [
    for table in local.dynamodb_tables : merge(
      {
        # Defaults
        seed_data_path = null
      },
      table,
      {
        # Computed values
        full_name = "${local.resource_prefix}-${table.name}"
        arn       = "arn:aws:dynamodb:${local.region}:${local.account_id}:table/${local.resource_prefix}-${table.name}"

        # Load seed items from the table's JSON file
        items = try(table.seed_data_path, null) == null ? [] : jsondecode(file(table.seed_data_path))
      }
    )
  ]

  # Create lookup map for cross-referencing
  dynamodb_tables_map = {
    for table in local.dynamodb_tables_enriched : table.name => table
  }
}

# ============================================================================
# IAM Roles Enrichment
# ============================================================================

locals {
  # Enrich IAM role data with computed values
  iam_roles_enriched = [
    for role in local.iam_roles : merge(
      {
        # Defaults
        path = "/"
      },
      role,
      {
        # Computed values
        full_name = "${local.resource_prefix}-${role.name}"
        arn       = "arn:aws:iam::${local.account_id}:role/${local.resource_prefix}-${role.name}"
      }
    )
  ]

  # Create lookup map for cross-referencing
  iam_roles_map = {
    for role in local.iam_roles_enriched : role.name => role
  }
}

# ============================================================================
# Lambda Functions Enrichment
# ============================================================================

locals {
  # Enrich Lambda data with computed values and resolve cross-references
  lambdas_enriched = [
    for lambda in local.lambdas : merge(
      {
        # Defaults
        timeout                        = 900
        memory                         = 512
        environment_variables          = {}
        lambda_layers                  = []
        storage                        = 512
        reserved_concurrent_executions = -1
        security_group_ids             = []
        subnet_ids                     = []
        policy_statements              = []
      },
      lambda,
      {
        # Computed values
        arn           = "arn:aws:lambda:${local.region}:${local.account_id}:function:${local.resource_prefix}-${lambda.name}"
        function_name = "${local.resource_prefix}-${lambda.name}"
        role_name     = "${local.resource_prefix}-${lambda.name}"
      }
    )
  ]

  # Create lookup map for cross-referencing
  lambdas_map = {
    for lambda in local.lambdas_enriched : lambda.name => lambda
  }
}

# ============================================================================
# API Gateway Enrichment
# ============================================================================

locals {
  # Enrich API Gateway data with computed values and resolve cross-references
  api_gateways_enriched = [
    for api in local.api_gateways : merge(
      {
        # Defaults
        allowed_lambda_names = []
        quota_limit          = 10
        quota_offset         = 0
        quota_period         = "DAY"
        burst_limit          = 5
        rate_limit           = 10
        api_keys             = []
        custom_domain        = null
      },
      api,
      {
        # Computed values
        full_name = "${local.resource_prefix}-${api.name}"

        # Resolve Lambda function names from short names
        allowed_lambda_function_names = [
          for lambda_name in api.allowed_lambda_names :
          local.lambdas_map[lambda_name].function_name
        ]
      },
      # Merge custom domain if present
      api.custom_domain != null ? {
        custom_domain = {
          domain_name     = "${api.custom_domain.subdomain_name}.${local.base_domain}"
          certificate_arn = var.dns_certificate_arn_regional
        }
      } : {}
    )
  ]

  # Create lookup map for cross-referencing
  api_gateways_map = {
    for api in local.api_gateways_enriched : api.name => api
  }
}

# ============================================================================
# S3 Files Enrichment
# ============================================================================

locals {
  # Enrich S3 files data with computed values and resolve cross-references
  s3_files_enriched = [
    for file in local.s3_files : merge(
      {
        # Defaults
        content_type       = null
        template_variables = {}
      },
      file,
      {
        # Computed values - resolve bucket references
        bucket_id = local.buckets_map[file.bucket_name].full_name
      }
    )
  ]

  # Create lookup map for cross-referencing
  s3_files_map = {
    for file in local.s3_files_enriched : file.name => file
  }
}
