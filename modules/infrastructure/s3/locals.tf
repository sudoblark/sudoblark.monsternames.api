locals {
  # Create a map for efficient lookups
  buckets_map = {
    for bucket in var.buckets : bucket.name => bucket
  }

  # Flatten folder paths for object creation
  folders = flatten([
    for bucket in var.buckets : [
      for folder in bucket.folder_paths : {
        bucket_name = bucket.full_name
        folder_path = folder
        key         = "${bucket.name}/${folder}"
      }
    ]
  ])

  folders_map = {
    for folder in local.folders : folder.key => folder
  }
}
