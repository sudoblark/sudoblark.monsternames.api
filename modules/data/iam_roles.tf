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
    - resources (list(string)): Short names or ARNs (enriched in infrastructure.tf)

  Optional fields:
  - path (string): IAM path for the role (default: "/")
  - conditions (list(object)): Conditions for assume role policy (default: [])

  Constraints:
  - Full role name must be less than 64 characters
  - SID must be alphanumeric (no spaces or special characters)

  Resource References (resolved in infrastructure.tf):
  - "assets" → S3 bucket ARN
  - "assets/*" → S3 bucket objects ARN
  - "dynamodb:*" → DynamoDB tables ARN pattern
  - "logs:*" → CloudWatch Logs ARN pattern

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
        resources = ["assets/*"]  # Resolved to full ARN
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
            # Will be enriched to use buckets_map
            "assets"
          ]
        },
        {
          sid    = "AllowGetObjectAssetsBucket"
          effect = "Allow"
          actions = [
            "s3:GetObject"
          ]
          resources = [
            # Will be enriched to use buckets_map
            "assets/*"
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
          sid    = "AllowDynamoDBFullAccess"
          effect = "Allow"
          actions = [
            "dynamodb:*"
          ]
          resources = [
            # Will be enriched with region and account
            "dynamodb:*"
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
          resources = [
            # Will be enriched with region, account, and resource prefix
            "logs:*"
          ]
        }
      ]
    }
  ]
}
