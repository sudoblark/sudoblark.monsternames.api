/*
  IAM Roles data structure definition:

  Each object requires:
  - name (string): Short name for the role (auto-prefixed with aws-sudoblark-production-monsternames-api)
  - assume_policy_principals (list(object)): List of principals that can assume the role
    - type (string): Principal type (Service, AWS, Federated)
    - identifiers (list(string)): List of principal identifiers
  - policy_statements (list(object)): List of IAM policy statements
    - sid (string): Statement ID
    - effect (string): Allow or Deny
    - actions (list(string)): List of IAM actions
    - resources (list(string)): ARNs, taken from other primitives' lookup maps where they exist

  Optional fields:
  - path (string): IAM path for the role (default: "/")

  Constraints:
  - Full role name must be at most 64 characters
  - path must start and end with "/"
  - SID must be alphanumeric (no spaces or special characters)
  - effect must be Allow or Deny
  - The iam module enforces these with validation blocks
  - Reference other primitives through their maps (e.g. local.buckets_map["assets"].arn)
    rather than writing their names by hand

  Example:
  {
    name = "api-gateway"
    assume_policy_principals = [
      {
        type        = "Service"
        identifiers = ["apigateway.amazonaws.com"]
      }
    ]
    policy_statements = [
      {
        sid       = "AllowS3Access"
        effect    = "Allow"
        actions   = ["s3:GetObject"]
        resources = ["${local.buckets_map["assets"].arn}/*"]
      }
    ]
  }
*/

locals {
  iam_roles = [
    {
      name = "api-gateway"
      assume_policy_principals = [
        {
          type        = "Service"
          identifiers = ["apigateway.amazonaws.com"]
        }
      ]
      policy_statements = [
        {
          sid    = "AllowListAssetBucket"
          effect = "Allow"
          actions = [
            "s3:ListBucket",
            "s3:GetBucketAcl"
          ]
          resources = [
            local.buckets_map["assets"].arn
          ]
        },
        {
          sid    = "AllowGetObjectAssetsBucket"
          effect = "Allow"
          actions = [
            "s3:GetObject"
          ]
          resources = [
            "${local.buckets_map["assets"].arn}/*"
          ]
        }
      ]
    },
    {
      name = "backend-lambda"
      assume_policy_principals = [
        {
          type        = "Service"
          identifiers = ["lambda.amazonaws.com"]
        }
      ]
      policy_statements = [
        {
          sid    = "AllowReadNameTables"
          effect = "Allow"
          actions = [
            "dynamodb:Scan"
          ]
          # Every table in dynamodb_tables.tf
          resources = [
            for table in local.dynamodb_tables_map : table.arn
          ]
        },
        {
          sid    = "AllowCloudWatchLogs"
          effect = "Allow"
          actions = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          # This project's Lambda log groups
          resources = [
            "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${local.resource_prefix}-*"
          ]
        }
      ]
    }
  ]
}
