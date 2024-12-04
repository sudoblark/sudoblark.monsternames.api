/*
Data structure
---------------
A list of dictionaries, where each dictionary has the following attributes:

REQUIRED
---------
- name      : The name of the bucket.


OPTIONAL
---------
- log_bucket                 : Target bucket name for access logging, defaults to null and thus not enabled.
- prefixes                   : A list of prefixes to pre-create in the bucket, defaults to empty list.
- versioning                 : Boolean to determine if versioning is enabled or not. Defaults to true.
- bucket_policy_json         : JSON bucket policy. Defaults to null. Use to restrict access to the bucket in a more granular fashion.
- days_retention             : How many days an item is retained in the bucket before being deleted. Defaults to 365.
- multipart_retention        : How many days incomplete multipart uploads should remain in bucket. Defaults to 7.
- enable_event_bridge        : Whether to enable event_bridge on the bucket. Defaults to False.
- enable_kms                 : Whether to enable KMS encryption of objects at rest. Defaults to False.
- kms_allowed_principals     : An list of dictionaries (defaults to empty list), which each defines:
-- type                      : A string defining what type the principle(s) is/are
-- identifiers               : A list of strings, where each string is an allowed principle
 */

locals {
  raw_s3_buckets = [
    {
      name : "assets",
      versioning : true,
      enable_kms : true,
      prefixes = [
        "swagger_ui/"
      ]
    },
  ]
}