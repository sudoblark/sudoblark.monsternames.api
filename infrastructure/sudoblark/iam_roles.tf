module "iam_roles" {
  source           = "../modules/iam_roles"
  application_name = var.application_name
  environment      = var.environment

  depends_on = [
    module.application_registry
  ]
}