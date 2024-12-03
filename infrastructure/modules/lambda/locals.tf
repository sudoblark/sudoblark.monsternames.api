/*
Data structure
---------------
A list of dictionaries, where each dictionary has the following attributes:

REQUIRED
---------
- name                  : The friendly name of for the lambda
- description           : A human-friendly description of the lambda
- iam_policy_statements : A list of dictionaries where each dictionary is an IAM statement defining lambda permissions
-- Each dictionary in this list must define the following attributes:
--- sid: Friendly name for the policy, no spaces or special characters allowed
--- actions: A list of IAM actions the lambda is allowed to perform
--- resources: Which resource(s) the lambda may perform the above actions against
--- conditions    : An OPTIONAL list of dictionaries, which each defines:
---- test         : Test condition for limiting the action
---- variable     : Value to test
---- values       : A list of strings, denoting what to test for

MUTUALLY_EXCLUSIVE
---------
There are a few flavours of lambdas supported, but they are mutually exclusive.
You can have both in the same collection, but you can't have both for the same lambda.
i.e. you can have one dictionary for ZIP and one for containers, but not ZIP and container
information in the same lambda

For ZIP based lambdas, the following arguments are needed:
- source_folder         : Folder where the zipped lambda lives under src/lambda.zip
- handler               : file.function reference for the lambda handler, i.e. its entrypoint

For container based lambdas, the following arguments are needed:
- image_uri             : URI of the image to utilise
- image_tag             : Version of image to use, defaults to "latest"

OPTIONAL
---------
- environment_variables : A dictionary of env vars to mount for the lambda at runtime, defaults to an empty dictionary
- runtime               : Runtime version to utilise for lambda, defaults to python3.9
- timeout               : Timeout (in seconds) for the lambda, defaults to 900
- memory                : MBs of memory lambda should be allocated, defaults to 512
- security_group_ids    : IDs of security groups the lambda should utilise
- lambda_subnet_ids     : Private IPs which the lambda may utilise for runtime
- storage               : MBs of storage lambda should be allocated, defaults to 512
- common_lambda_layers  : ARNs of lambda layers to include.
- destination_on_failure: ARN of resource to notify when an invocation fails.
*/

locals {
  raw_lambdas = [
    {
      name          = "backend"
      iam_suffix    = "bl"
      description   = "Ingests, and retrieves, monsternames from DynamoDB"
      source_folder = "application/backend-lambda"
      handler       = "backend_lambda.main.handler"
      runtime       = "python3.10"
      package_type  = "Zip"
      timeout       = "900"
      memory        = "256"
      common_lambda_layers = [
        "arn:aws:lambda:${data.aws_region.current_region.name}:017000801446:layer:AWSLambdaPowertoolsPythonV2:73"
      ]
      environment_variables = {
        "LOG_LEVEL" : "DEBUG",
        "CONFIG_FILE" : "config.ini"
      }
      iam_policy_statements = [
        {
          sid = "AllowDynamoDBFullAccessToADOTables"
          actions = [
            "dynamodb:*"
          ]
          resources = [
            "arn:aws:dynamodb:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_account.account_id}:table/*"
          ]
        },
      ]
    },
  ]
}