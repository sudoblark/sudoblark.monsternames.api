locals {
  actual_restapi_gateways = flatten([
    for api in local.raw_restapi_gateways : merge(api, {
      // Auto navigate to root of directory to allow easier definitions in our locals.tf
      open_api_file_path = "${path.module}/../../../${api.open_api_file_path}"
    })
  ])
}

module "restapi_gateway" {
  source = "github.com/sudoblark/sudoblark.terraform.module.aws.api_gateway?ref=1.0.0"

  application_name          = var.application_name
  environment               = var.environment
  raw_api_gateway_rest_apis = local.actual_restapi_gateways
}
