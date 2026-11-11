/*
  Lambda Functions data structure definition:

  Each object requires:
  - name (string): Short name for the Lambda (auto-prefixed with aws-sudoblark-production-monsternames-api)
  - description (string): Human-friendly description
  - handler (string): Lambda handler (e.g., "module.handler")
  - runtime (string): Runtime version (e.g., "python3.13")
  - zip_file_path (string): Path to deployment package relative to repo root

  Optional fields:
  - timeout (number): Timeout in seconds (default: 900)
  - memory (number): Memory in MB (default: 512)
  - environment_variables (map(string)): Environment variables (default: {})
  - lambda_layers (list(string)): Layer ARNs, in this region (default: [])
  - storage (number): Ephemeral storage in MB (default: 512)
  - reserved_concurrent_executions (number): Concurrency limit (default: -1, unreserved)
  - policy_statements (list(object)): What the function may do, beyond writing
    its own logs (default: [])
    - sid (string): Statement ID
    - effect (string): Allow or Deny
    - actions (list(string)): List of IAM actions
    - resources (list(string)): ARNs, taken from other primitives' lookup maps where they exist

  Each function gets its own IAM role, with the function's name. The lambda
  module creates it from policy_statements, and adds the statement that lets
  the function write to its own log group.

  Constraints:
  - Full Lambda name must be at most 64 characters
  - timeout must be 1-900, memory 128-10240 and storage 512-10240
  - reserved_concurrent_executions must be -1 (unreserved) or more
  - SID must be alphanumeric (no spaces or special characters)
  - effect must be Allow or Deny
  - zip_file_path must exist and contain valid deployment package
  - The lambda module enforces the limits above with validation blocks
  - Reference other primitives through their maps (e.g. local.dynamodb_tables_map["goblin-first-name"].arn)
    rather than writing their names by hand

  Example:
  {
    name        = "backend"
    description = "Handles API requests for monster names"
    handler     = "backend_lambda.main.handler"
    runtime     = "python3.13"
    zip_file_path = "./lambda-packages/backend.zip"
    timeout     = 60
    memory      = 256
    lambda_layers = ["arn:aws:lambda:${local.region}:017000801446:layer:AWSLambdaPowertoolsPythonV3-python313-x86_64:42"]
    environment_variables = {
      LOG_LEVEL = "INFO"
    }
    policy_statements = [
      {
        sid       = "AllowReadGoblinNames"
        effect    = "Allow"
        actions   = ["dynamodb:Scan"]
        resources = [local.dynamodb_tables_map["goblin-first-name"].arn]
      }
    ]
  }
*/

locals {
  lambdas = [
    {
      name          = "backend"
      description   = "Retrieves monster names from DynamoDB"
      handler       = "backend_lambda.main.handler"
      runtime       = "python3.13"
      zip_file_path = "../../lambda-packages/backend.zip"
      timeout       = 29
      memory        = 256
      lambda_layers = [
        # Powertools for AWS Lambda (Python) v3, which AWS publishes in every
        # region. The layer is built per Python version and architecture, so
        # it changes with the runtime. pyproject.toml pins the same
        # release for the tests.
        "arn:aws:lambda:${local.region}:017000801446:layer:AWSLambdaPowertoolsPythonV3-python313-x86_64:42"
      ]
      environment_variables = {
        LOG_LEVEL = "INFO"

        # Each monster in monsters.tf and its name tables, as JSON
        MONSTER_TABLES = jsonencode({
          for monster in local.monsters : monster.name => {
            first_name = local.dynamodb_tables_map["${monster.name}-first-name"].full_name
            last_name  = try(local.dynamodb_tables_map["${monster.name}-last-name"].full_name, null)
          }
        })
      }
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
        }
      ]
    }
  ]
}
