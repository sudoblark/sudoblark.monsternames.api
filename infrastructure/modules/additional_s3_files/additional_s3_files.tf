locals {
  actual_raw_s3_files = flatten([
    for file in local.raw_s3_files : merge(file, {
      // Simply replace source_folder attribute with one specifically targeting module root
      source_folder = "${path.module}/../../../${file.source_folder}"
    })
  ])
}

module "s3_files" {
  source       = "github.com/sudoblark/sudoblark.terraform.module.aws.s3_files?ref=1.0.0"
  raw_s3_files = local.actual_raw_s3_files

}