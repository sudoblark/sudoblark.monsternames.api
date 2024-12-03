module "api_gateway" {
  source           = "../modules/api_gateway_rest_api"
  application_name = var.application_name
  environment      = var.environment

  depends_on = [
    module.lambda
  ]

}