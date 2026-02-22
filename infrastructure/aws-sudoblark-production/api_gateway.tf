# API Gateway REST APIs
module "api_gateway" {
  source = "../../modules/infrastructure/api-gateway"

  api_gateways = module.data.api_gateways
  dns_zone_id  = module.data.dns_zone_id

  depends_on = [
    module.lambda
  ]
}
