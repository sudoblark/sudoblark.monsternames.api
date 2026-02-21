/*
  API Gateway REST APIs data structure definition:

  Each object requires:
  - name (string): Short name for the API Gateway (auto-prefixed with aws-sudoblark-production-monsternames-api)
  - description (string): Human-friendly description
  - openapi_spec_path (string): Path to OpenAPI specification file
  - template_variables (map(string)): Variables to interpolate into OpenAPI spec (short names)

  Optional fields:
  - allowed_lambda_names (list(string)): Lambda names to grant invoke permissions (default: [])
  - quota_limit (number): Maximum requests per quota period (default: 10)
  - quota_offset (number): Request offset for initial period (default: 0)
  - quota_period (string): DAY, WEEK, or MONTH (default: "DAY")
  - burst_limit (number): Maximum burst rate limit (default: 5)
  - rate_limit (number): Steady-state rate limit (default: 10)
  - api_keys (list(string)): API key names to create (default: [], typically not needed)

  Constraints:
  - openapi_spec_path must point to valid OpenAPI 3.0+ specification
  - allowed_lambda_names must reference existing Lambdas in lambdas.tf
  - quota_period must be one of: DAY, WEEK, MONTH

  Template Variable References (resolved in infrastructure.tf):
  - Lambda names → Full Lambda ARNs
  - Bucket names → Full bucket names
  - IAM role names → Full role ARNs
  - "region" → AWS region

  Example:
  {
    name                = "backend"
    description         = "Monster Names API"
    openapi_spec_path   = "./application/openapi/spec.yaml"
    template_variables = {
      backend_lambda_arn       = "backend"      # Resolved to ARN
      aws_region_name          = "region"       # Resolved to actual region
      asset_bucket_name        = "assets"       # Resolved to full name
      api_gateway_iam_role_arn = "api-gateway"  # Resolved to ARN
    }
    allowed_lambda_names = ["backend"]
    quota_limit          = 500
    rate_limit           = 100
    api_keys             = ["ingestion"]
  }
*/

locals {
  api_gateways = [
    {
      name                = "backend"
      description         = "This is a relatively simple REST API, based on the OpenAPI 3.0 specification, which generates pseudo-random names for common fantasy monsters."
      openapi_spec_path   = "../../application/open_api_definitions/monsternames.yaml"
      template_variables = {
        # Will be enriched with actual ARNs and values
        backend_lambda_arn       = "backend"
        aws_region_name          = "region"
        asset_bucket_name        = "assets"
        swagger_index_path       = "swagger_ui/index.html"
        api_gateway_iam_role_arn = "api-gateway"
      }
      allowed_lambda_names = ["backend"]
      quota_limit          = 500
      rate_limit           = 100
      api_keys             = ["admin"]  # For POST endpoints
      custom_domain = {
        subdomain_name = "monsternames"
      }
    }
  ]
}
