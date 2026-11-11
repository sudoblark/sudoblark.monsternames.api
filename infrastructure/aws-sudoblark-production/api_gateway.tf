# API Gateway's account-wide settings, which every API in this account and
# region shares
module "api_gateway_account" {
  source = "../../modules/infrastructure/api-gateway-account"

  api_gateway_account = module.data.api_gateway_account
}

# API Gateway REST APIs
module "api_gateway" {
  source = "../../modules/infrastructure/api-gateway"

  api_gateways = module.data.api_gateways
  dns_zone_id  = module.data.dns_zone_id

  depends_on = [
    module.lambda,
    module.api_gateway_account
  ]
}
