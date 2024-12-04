module "s3_bucket" {
  source           = "../modules/s3_bucket"
  application_name = var.application_name
  environment      = var.environment
}