locals {
  actual_raw_lambdas = flatten([
    for lambda in local.raw_lambdas : merge(lambda, {
      // Auto navigate to root of directory to allow easier definitions in our locals.tf
      source_folder = lambda.source_folder != null ? "${path.module}/../../../${lambda.source_folder}" : null
    })
  ])
}

module "lambda" {
  source           = "github.com/sudoblark/sudoblark.terraform.module.aws.lambda?ref=1.0.1"
  application_name = var.application_name
  environment      = var.environment
  raw_lambdas      = local.actual_raw_lambdas
}