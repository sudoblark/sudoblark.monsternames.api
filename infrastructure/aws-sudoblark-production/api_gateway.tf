# API Gateway REST APIs
module "api_gateway" {
  source = "../../modules/infrastructure/api-gateway"

  api_gateways = module.data.api_gateways

  depends_on = [
    module.lambda
  ]
}
