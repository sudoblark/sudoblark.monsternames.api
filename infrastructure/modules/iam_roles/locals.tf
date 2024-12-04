/*
Data structure
---------------
A list of dictionaries, where each dictionary has the following attributes:

REQUIRED
---------
- suffix                : Suffix to use for the role name
- iam_policy_statements : A list of dictionaries where each dictionary is an IAM statement defining permissions
-- Each dictionary in this list must define the following attributes:
--- sid: Friendly name for the policy, no spaces or special characters allowed
--- actions: A list of IAM actions the role is allowed to perform
--- resources: Which resource(s) the role may perform the above actions against
--- conditions    : An OPTIONAL list of dictionaries, which each defines:
---- test         : Test condition for limiting the action
---- variable     : Value to test
---- values       : A list of strings, denoting what to test for

OPTIONAL
---------
- path                  : Path to create the role and policies under, defaults to "/"

- assume_policy_principles : A list of dictionaries where each dictionary defines a principle allowed to assume the role.
-- Each dictionary in this list must define the following attributes:
--- type          : A string defining what type the principle(s) is/are
--- identifiers   : A list of strings, where each string is an allowed principle
--- conditions    : An OPTIONAL list of dictionaries, which each defines:
---- test         : Test condition for limiting the action
---- variable     : Value to test
---- values       : A list of strings, denoting what to test for


Constraints
---------------
- <var.environment>-<var.application_name>-<suffix> has
to be lower than 38 characters due to IAM role naming requirements. Cannot encode in variable validation as
string interpolations are not allowed in variables.
*/

locals {
  raw_iam_roles = [
    {
      suffix = "api-gateway",
      assume_policy_principles = [
        {
          "type" : "Service",
          "identifiers" : [
            "apigateway.amazonaws.com"
          ]
        }
      ],
      iam_policy_statements = [
        {
          sid    = "AllowListAssetBucket"
          effect = "Allow"
          actions = [
            "s3:ListBucket",
            "s3:GetBucketAcl"
          ]
          resources = [
            local.known_buckets.assets.arn
          ]
        },
        {
          sid    = "AllowGetObjectAssetsBucket"
          effect = "Allow"
          actions = [
            "s3:GetObject",
          ]
          resources = [
            "${local.known_buckets.assets.arn}/*"
          ]
        },
        {
          sid    = "AllowKMSDecryptAssetsBucket",
          effect = "Allow",
          actions = [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          resources = [
            data.aws_kms_key.known_keys["assets-bucket"].arn,
          ]
        }
      ]
    },
  ]
}