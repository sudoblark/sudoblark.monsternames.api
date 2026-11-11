# Lambda Functions, each with its own IAM role
module "lambda" {
  source = "../../modules/infrastructure/lambda"

  lambdas = module.data.lambdas

  depends_on = [
    module.dynamodb
  ]
}
