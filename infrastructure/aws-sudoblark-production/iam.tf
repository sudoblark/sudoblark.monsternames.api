# IAM Roles
module "iam" {
  source = "../../modules/infrastructure/iam"

  iam_roles = module.data.iam_roles
}
