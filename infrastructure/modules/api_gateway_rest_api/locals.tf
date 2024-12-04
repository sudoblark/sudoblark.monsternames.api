/*
Data structure
---------------
A list of dictionaries, where each dictionary has the following attributes:

REQUIRED
---------
- suffix                : Suffix to use when creating the RESTAPI Gateway
- open_api_file_path    : Path to OpenAPI definition file
- description           : A human-friendly description of the API


OPTIONAL
---------
- template_input        : A dictionary of variable input for the OpenAPI definition file (leave blank if no template required)
- allowed_lambdas       : A list of strings, where each string is the function_name of a lambda to allow access to.
- quota_limit           : Maximum number of requests that can be made in a given time period, defaults to 10.
- quota_offset          : Number of requests subtracted from the given limit in the initial time period, defaults to 0.
- quota_period          : Time period in which the limit applies. Valid values are "DAY", "WEEK" or "MONTH". Defaults to "DAY"
- burst_limit           : The API request burst limit, the maximum rate limit over a time ranging from one to a few seconds, depending upon whether the underlying token bucket is at its full capacity. Defaults to 5.
- rate_limit            : The API request steady-state rate limit, defaults to 10.
- api_keys              : List of strings, where each string is name of an API key to create for the API, defaults to empty list.
*/

locals {
  raw_restapi_gateways = [
    {
      suffix = "backend"
      open_api_file_path : "application/open_api_definitions/monsternames.yaml"
      description = "    This is a relatively simple RESTAPI, based on the OpenAPI 3.0 specification, which generates pseudo-random names for common fantasy monsters."
      template_input = {
        backend_lambda_arn : data.aws_lambda_function.known_lambdas["backend-lambda"].arn,
        aws_region_name : data.aws_region.current_region.name,
        asset_bucket_name : local.known_buckets.assets.name,
        swagger_index_path : "swagger_ui/index.html",
        api_gateway_iam_role_arn : local.known_roles.api_gateway_iam_role_arn.arn
      }
      allowed_lambdas = [
        data.aws_lambda_function.known_lambdas["backend-lambda"].function_name,
      ]
      quota_limit = 500
      rate_limit  = 100
      api_keys    = ["ingestion"]
    }
  ]
}