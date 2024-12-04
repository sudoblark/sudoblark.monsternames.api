module "s3_bucket" {
  source           = "github.com/sudoblark/sudoblark.terraform.module.aws.s3_bucket?ref=1.0.2"
  application_name = var.application_name
  environment      = var.environment
  raw_s3_buckets   = local.raw_s3_buckets
}