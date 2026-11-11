/*
  Default values used across all infrastructure resources, and the settings
  that differ between the accounts this repo deploys to.

  accounts holds one entry per account, keyed by the account name an
  environment root passes as var.account. Each entry requires:
  - environment (string): Short name for the environment (e.g. "production")
  - api_stage_name (string): Name of each API's deployment stage
  - log_retention_days (number): Days to keep CloudWatch logs

  Deploying to another account takes an entry here, and an environment root
  of its own under infrastructure/ that passes its name.

  Example:
  "aws-sudoblark-staging" = {
    environment        = "staging"
    api_stage_name     = "staging"
    log_retention_days = 7
  }
*/

locals {
  # Each account this repo deploys to, and its settings
  accounts = {
    "aws-sudoblark-production" = {
      environment        = "production"
      api_stage_name     = "production"
      log_retention_days = 14
    }
  }

  # Account and project identifiers
  account     = var.account
  project     = "monsternames"
  application = "api"

  # The settings for the account being deployed
  account_settings = local.accounts[var.account]
  environment      = local.account_settings.environment

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
