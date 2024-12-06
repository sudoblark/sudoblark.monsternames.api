module "additional_s3_files" {
  source           = "../modules/additional_s3_files"
  application_name = var.application_name
  environment      = var.environment

  depends_on = [
    module.s3_bucket,
    module.application_registry
  ]
}