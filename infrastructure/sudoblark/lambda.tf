module "lambda" {
  source           = "../modules/lambda"
  application_name = var.application_name
  environment      = var.environment
}