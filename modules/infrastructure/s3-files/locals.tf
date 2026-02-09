locals {
  # Create a map for efficient lookups
  s3_files_map = {
    for file in var.s3_files : file.name => file
  }

  # Separate templated files from regular files
  templated_files = {
    for k, v in local.s3_files_map : k => v
    if length(v.template_variables) > 0
  }

  regular_files = {
    for k, v in local.s3_files_map : k => v
    if length(v.template_variables) == 0
  }
}
