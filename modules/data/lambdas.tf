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
  - lambda_layers (list(string)): Layer names or ARNs (default: [])
  - storage (number): Ephemeral storage in MB (default: 512)
  - reserved_concurrent_executions (number): Concurrency limit (default: -1, unreserved)

  Constraints:
  - Full Lambda name must be less than 64 characters
  - role_name must reference an existing IAM role in iam_roles.tf
  - zip_file_path must exist and contain valid deployment package

  Lambda Layer References (resolved in infrastructure.tf):
  - "powertools-python" → Full ARN for AWS Lambda Powertools Python layer

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
    lambda_layers = ["powertools-python"]  # Resolved to full ARN
    environment_variables = {
      LOG_LEVEL   = "INFO"
      CONFIG_FILE = "config.ini"
    }
  }
*/

locals {
  lambdas = [
    {
      name        = "backend"
      description = "Ingests and retrieves monsternames from DynamoDB"
      handler     = "backend_lambda.main.handler"
      runtime     = "python3.11"
      role_name   = "backend-lambda"
      zip_file_path = "../../lambda-packages/backend.zip"
      timeout     = 900
      memory      = 256
      lambda_layers = [
        # Will be enriched with region
        "powertools-python"
      ]
      environment_variables = {
        LOG_LEVEL   = "DEBUG"
        CONFIG_FILE = "config.ini"
      }
    }
  ]
}
