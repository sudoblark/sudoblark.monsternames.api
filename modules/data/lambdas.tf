/*
  Lambda Functions data structure definition:

  Each object requires:
  - name (string): Short name for the Lambda (auto-prefixed with aws-sudoblark-production-monsternames-api)
  - description (string): Human-friendly description
  - handler (string): Lambda handler (e.g., "module.handler")
  - runtime (string): Runtime version (e.g., "python3.11")
  - role_name (string): Name of IAM role (references iam_roles by name)
  - zip_file_path (string): Path to deployment package relative to repo root

  Optional fields:
  - timeout (number): Timeout in seconds (default: 900)
  - memory (number): Memory in MB (default: 512)
  - environment_variables (map(string)): Environment variables (default: {})
  - lambda_layers (list(string)): Layer ARNs, in this region (default: [])
  - storage (number): Ephemeral storage in MB (default: 512)
  - reserved_concurrent_executions (number): Concurrency limit (default: -1, unreserved)

  Constraints:
  - Full Lambda name must be at most 64 characters
  - timeout must be 1-900, memory 128-10240 and storage 512-10240
  - reserved_concurrent_executions must be -1 (unreserved) or more
  - role_name must reference an existing IAM role in iam_roles.tf
  - zip_file_path must exist and contain valid deployment package
  - The lambda module enforces the limits above with validation blocks

  Example:
  {
    name        = "backend"
    description = "Handles API requests for monster names"
    handler     = "backend_lambda.main.handler"
    runtime     = "python3.11"
    role_name   = "backend-lambda"
    zip_file_path = "./lambda-packages/backend.zip"
    timeout     = 60
    memory      = 256
    lambda_layers = ["arn:aws:lambda:${local.region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:73"]
    environment_variables = {
      LOG_LEVEL = "INFO"
    }
  }
*/

locals {
  lambdas = [
    {
      name          = "backend"
      description   = "Retrieves monster names from DynamoDB"
      handler       = "backend_lambda.main.handler"
      runtime       = "python3.11"
      role_name     = "backend-lambda"
      zip_file_path = "../../lambda-packages/backend.zip"
      timeout       = 29
      memory        = 256
      lambda_layers = [
        # AWS Lambda Powertools for Python, which AWS publishes in every region
        "arn:aws:lambda:${local.region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:73"
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
    }
  ]
}
