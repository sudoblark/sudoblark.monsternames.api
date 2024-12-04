module "iam_roles" {
  source           = "github.com/sudoblark/sudoblark.terraform.module.aws.iam_role?ref=1.0.0"
  application_name = var.application_name
  environment      = var.environment
  raw_iam_roles    = local.raw_iam_roles
}