/*
  API Gateway account settings definition:

  API Gateway writes every API's execution logs, in this account and region,
  through one CloudWatch role set in the account's API Gateway settings. No one
  API owns it, so it is a single object rather than a list, with a module of
  its own. Only one repo per account and region should manage it.

  The object requires:
  - cloudwatch_role_name (string): Name of the role API Gateway assumes to write logs

  Constraints:
  - cloudwatch_role_name must be at most 64 characters
  - The api-gateway-account module enforces this with a validation block

  Example:
  {
    cloudwatch_role_name = "aws-sudoblark-production-api-gateway-cloudwatch"
  }
*/

locals {
  api_gateway_account = {
    # Named for the account, since the setting covers every API in it
    cloudwatch_role_name = "${local.account}-api-gateway-cloudwatch"
  }
}
