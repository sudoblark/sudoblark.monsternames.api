/*
Data structure
---------------
A list of dictionaries, where each dictionary has the following attributes:

REQUIRED
---------
- name:                 : Friendly name used through Terraform for instantiation and cross-referencing of resources,
                          only relates to resource naming within the module.
- source_folder         : Which folder where the {source_file} lives.
- source_file           : The path under {source_folder} corresponding to the file to upload.
- destination_key       : Key in S3 bucket to upload to.
- destination_bucket    : The S3 bucket to upload the {source_file} to.

OPTIONAL
---------
- template_input        : A dictionary of variable input for the template file needed for instantiation (leave blank if no template required)
*/

locals {
  raw_s3_files = [
    {
      name : "config",
      source_folder : "application/swagger_ui/",
      source_file : "index.html",
      destination_bucket : local.known_buckets.assets.name,
      destination_key : "swagger_ui/index.html",
    },
  ]
}