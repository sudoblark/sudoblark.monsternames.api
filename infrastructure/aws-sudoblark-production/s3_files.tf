# S3 File Uploads
module "s3_files" {
  source = "../../modules/infrastructure/s3-files"

  s3_files = module.data.s3_files

  depends_on = [
    module.s3
  ]
}
