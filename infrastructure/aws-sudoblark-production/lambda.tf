# Lambda Functions
module "lambda" {
  source = "../../modules/infrastructure/lambda"

  lambdas = module.data.lambdas

  depends_on = [
    module.iam
  ]
}
