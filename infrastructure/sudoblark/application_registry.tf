module "application_registry" {
  source           = "../modules/application_registry"
  application_name = var.application_name
  environment      = var.environment

  providers = {
    aws.applicationRegistry : aws.applicationRegistry
  }
}