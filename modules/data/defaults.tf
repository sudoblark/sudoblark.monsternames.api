/*
  Default values used across all infrastructure resources.
  
  These values are applied consistently to all resources to ensure
  naming conventions and tagging standards are followed.
*/

locals {
  # Account and project identifiers
  account     = "aws-sudoblark-production"
  project     = "monsternames"
  application = "api"

  # AWS context
  region     = data.aws_region.current_region.region
  account_id = data.aws_caller_identity.current_account.account_id

  # Common resource prefix
  resource_prefix = "${local.account}-${local.project}-${local.application}"

  # Domain that custom domains' subdomain_name values sit under
  base_domain = "sudoblark.com"

  # Default tags applied to all resources
  default_tags = {
    environment = local.account
    managed_by  = "sudoblark.monsternames.api"
    project     = local.project
    application = local.application
  }
}
