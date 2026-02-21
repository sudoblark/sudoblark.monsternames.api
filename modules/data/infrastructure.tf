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
        account              = local.account
        project              = local.project
        application          = local.application
        folder_paths         = []
        days_retention       = 365
        multipart_retention  = 7
        enable_event_bridge  = false
        log_bucket           = null
        bucket_policy_json   = null
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
# IAM Roles Enrichment
# ============================================================================

locals {
  # Enrich IAM role data with computed values and resolve cross-references
  iam_roles_enriched = [
    for role in local.iam_roles : merge(
      {
        # Defaults
        account     = local.account
        project     = local.project
        application = local.application
        path        = "/"
        conditions  = []
      },
      role,
      {
        # Computed values
        full_name = "${local.resource_prefix}-${role.name}"
        arn       = "arn:aws:iam::${local.account_id}:role/${local.resource_prefix}-${role.name}"
        
        # Resolve policy statement resources with actual ARNs
        policy_statements = [
          for stmt in role.policy_statements : merge(
            stmt,
            {
              resources = [
                for resource in stmt.resources :
                # S3 bucket ARN resolution
                resource == "assets" ? local.buckets_map["assets"].arn :
                resource == "assets/*" ? "${local.buckets_map["assets"].arn}/*" :
                # DynamoDB ARN resolution
                resource == "dynamodb:*" ? "arn:aws:dynamodb:${local.region}:${local.account_id}:table/*" :
                # CloudWatch Logs ARN resolution
                resource == "logs:*" ? "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${local.resource_prefix}-*" :
                # Pass through if already an ARN
                resource
              ]
            }
          )
        ]
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
        account                        = local.account
        project                        = local.project
        application                    = local.application
        timeout                        = 900
        memory                         = 512
        environment_variables          = {}
        lambda_layers                  = []
        storage                        = 512
        reserved_concurrent_executions = -1
        security_group_ids             = []
        subnet_ids                     = []
      },
      lambda,
      {
        # Computed values
        full_name     = "${local.resource_prefix}-${lambda.name}"
        arn           = "arn:aws:lambda:${local.region}:${local.account_id}:function:${local.resource_prefix}-${lambda.name}"
        role_arn      = local.iam_roles_map[lambda.role_name].arn
        function_name = "${local.resource_prefix}-${lambda.name}"
        
        # Resolve Lambda layers to full ARNs
        lambda_layers = [
          for layer in lambda.lambda_layers :
          # PowerTools Python layer
          layer == "powertools-python" ? "arn:aws:lambda:${local.region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:73" :
          # Pass through if already an ARN
          layer
        ]
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
  # Determine base domain based on environment
  base_domain = local.account == "aws-sudoblark-production" ? "sudoblark.com" : "${replace(local.account, "aws-sudoblark-", "")}.sudoblark.com"
  
  # Enrich API Gateway data with computed values and resolve cross-references
  api_gateways_enriched = [
    for api in local.api_gateways : merge(
      {
        # Defaults
        account              = local.account
        project              = local.project
        application          = local.application
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
        
        # Resolve Lambda ARNs from names
        allowed_lambda_arns = [
          for lambda_name in api.allowed_lambda_names :
          local.lambdas_map[lambda_name].arn
        ]
        allowed_lambda_function_names = [
          for lambda_name in api.allowed_lambda_names :
          local.lambdas_map[lambda_name].function_name
        ]
        
        # Compute custom domain configuration
        custom_domain_computed = api.custom_domain != null ? {
          domain_name           = "${api.custom_domain.subdomain_name}.${local.base_domain}"
          certificate_arn       = var.dns_certificate_arn_regional
          create_route53_record = try(api.custom_domain.create_route53_record, false)
        } : null
        
        # Resolve template variables
        template_variables = {
          for key, value in api.template_variables :
          key => (
            # Lambda ARN resolution
            value == "backend" && key == "backend_lambda_arn" ? local.lambdas_map["backend"].arn :
            # Region resolution
            value == "region" ? local.region :
            # Bucket name resolution
            value == "assets" && key == "asset_bucket_name" ? local.buckets_map["assets"].full_name :
            # IAM role ARN resolution
            value == "api-gateway" && key == "api_gateway_iam_role_arn" ? local.iam_roles_map["api-gateway"].arn :
            # Pass through other values
            value
          )
        }
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
        account            = local.account
        project            = local.project
        application        = local.application
        content_type       = null
        template_variables = {}
      },
      file,
      {
        # Computed values - resolve bucket references
        bucket_id  = local.buckets_map[file.bucket_name].full_name
        bucket_arn = local.buckets_map[file.bucket_name].arn
      }
    )
  ]

  # Create lookup map for cross-referencing
  s3_files_map = {
    for file in local.s3_files_enriched : file.name => file
  }
}
