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

  Constraints:
  - openapi_spec_path must point to valid OpenAPI 3.0+ specification
  - allowed_lambda_names must reference existing Lambdas in lambdas.tf
  - quota_* fields only apply to APIs with api_keys
  - quota_period must be one of: DAY, WEEK, MONTH
  - Template variables reference other primitives through their maps
    (e.g. local.lambdas_map["backend"].arn) rather than writing names by hand

  Example:
  {
    name                = "backend"
    description         = "Monster Names API"
    openapi_spec_path   = "./application/openapi/spec.yaml"
    template_variables = {
      backend_lambda_arn       = local.lambdas_map["backend"].arn
      aws_region_name          = local.region
      asset_bucket_name        = local.buckets_map["assets"].full_name
      api_gateway_iam_role_arn = local.iam_roles_map["api-gateway"].arn
    }
    allowed_lambda_names = ["backend"]
    rate_limit           = 100
  }
*/

locals {
  # Variables for the OpenAPI spec template, shared with the public copy of the
  # spec in s3_files.tf
  openapi_template_variables = {
    backend_lambda_arn       = local.lambdas_map["backend"].arn
    aws_region_name          = local.region
    asset_bucket_name        = local.buckets_map["assets"].full_name
    swagger_index_path       = "swagger_ui/index.html"
    api_gateway_iam_role_arn = local.iam_roles_map["api-gateway"].arn

    # Each monster in monsters.tf gets a path and a tag
    monsters = jsonencode(local.monsters)
  }

  api_gateways = [
    {
      name              = "backend"
      description       = "This is a relatively simple REST API, based on the OpenAPI 3.0 specification, which generates pseudo-random names for common fantasy monsters."
      openapi_spec_path = "../../application/open_api_definitions/monsternames.yaml"
      template_variables = merge(local.openapi_template_variables, {
        include_integrations = "true"
      })
      allowed_lambda_names = ["backend"]
      rate_limit           = 100
      custom_domain = {
        subdomain_name = "monsternames"
      }
    }
  ]
}
