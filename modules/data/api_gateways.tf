/*
  API Gateway REST APIs data structure definition:

  Each object requires:
  - name (string): Short name for the API Gateway (auto-prefixed with aws-sudoblark-production-monsternames-api)
  - description (string): Human-friendly description
  - openapi_spec_path (string): Path to OpenAPI specification file
  - template_variables (map(string)): Variables to interpolate into the OpenAPI spec

  Optional fields:
  - allowed_lambda_names (list(string)): Lambda names to grant invoke permissions (default: [])
  - rate_limit (number): Stage throttling, steady-state requests per second for every caller (default: 10)
  - burst_limit (number): Stage throttling, requests allowed in a burst (default: 5)
  - api_keys (list(string)): API key names to create, with a usage plan for their quota (default: [])
  - quota_limit (number): Requests per quota period for each key (default: 10)
  - quota_offset (number): Request offset for the initial period (default: 0)
  - quota_period (string): DAY, WEEK, or MONTH (default: "DAY")
  - stage_name (string): Name of the API's deployment stage (default: the
    account's api_stage_name in defaults.tf)
  - policy_statements (list(object)): What the API's integrations may do, such as
    reading objects from S3 (default: [], no role)
    - sid (string): Statement ID
    - effect (string): Allow or Deny
    - actions (list(string)): List of IAM actions
    - resources (list(string)): ARNs, taken from other primitives' lookup maps where they exist

  An API with policy_statements gets an IAM role for its integrations to assume,
  named after the API with an -integrations suffix. The api-gateway module
  creates it, and its ARN is added to template_variables as
  api_gateway_iam_role_arn, for the spec's integrations to use as credentials.

  Constraints:
  - openapi_spec_path must point to valid OpenAPI 3.0+ specification
  - allowed_lambda_names must reference existing Lambdas in lambdas.tf
  - quota_* fields only apply to APIs with api_keys
  - quota_period must be one of: DAY, WEEK, MONTH
  - rate_limit must be positive, and burst_limit zero or more
  - stage_name must be 1-128 letters, numbers, hyphens or underscores
  - The full role name must be at most 64 characters
  - SID must be alphanumeric (no spaces or special characters)
  - effect must be Allow or Deny
  - The api-gateway module enforces the limits above with validation blocks
  - Template variables and policy resources reference other primitives through
    their maps (e.g. local.lambdas_map["backend"].arn) rather than writing names by hand

  Example:
  {
    name                = "backend"
    description         = "Monster Names API"
    openapi_spec_path   = "./application/openapi/spec.yaml"
    template_variables = {
      backend_lambda_arn = local.lambdas_map["backend"].arn
      aws_region_name    = local.region
      asset_bucket_name  = local.buckets_map["assets"].full_name
    }
    allowed_lambda_names = ["backend"]
    rate_limit           = 100
    policy_statements = [
      {
        sid       = "AllowGetObjectAssetsBucket"
        effect    = "Allow"
        actions   = ["s3:GetObject"]
        resources = ["${local.buckets_map["assets"].arn}/*"]
      }
    ]
  }
*/

locals {
  api_gateways = [
    {
      name              = "backend"
      description       = "This is a relatively simple REST API, based on the OpenAPI 3.0 specification, which generates pseudo-random names for common fantasy monsters."
      openapi_spec_path = "../../application/open_api_definitions/monsternames.yaml"
      template_variables = {
        backend_lambda_arn = local.lambdas_map["backend"].arn
        aws_region_name    = local.region
        asset_bucket_name  = local.buckets_map["assets"].full_name
        swagger_index_path = "swagger_ui/index.html"

        # Each monster in monsters.tf gets a path and a tag
        monsters = jsonencode(local.monsters)

        # The public copy of the spec in s3_files.tf sets this to "false"
        include_integrations = "true"
      }
      allowed_lambda_names = ["backend"]
      rate_limit           = 100
      custom_domain = {
        subdomain_name = "monsternames"
      }
      # The Swagger UI and the public spec at / and /openapi are S3 integrations
      policy_statements = [
        {
          sid    = "AllowListAssetBucket"
          effect = "Allow"
          actions = [
            "s3:ListBucket",
            "s3:GetBucketAcl"
          ]
          resources = [
            local.buckets_map["assets"].arn
          ]
        },
        {
          sid    = "AllowGetObjectAssetsBucket"
          effect = "Allow"
          actions = [
            "s3:GetObject"
          ]
          resources = [
            "${local.buckets_map["assets"].arn}/*"
          ]
        }
      ]
    }
  ]
}
