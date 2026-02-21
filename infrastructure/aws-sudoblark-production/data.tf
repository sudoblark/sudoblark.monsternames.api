# Data module - Defines all infrastructure as data structures
module "data" {
  source = "../../modules/data"

  dns_zone_id                  = local.dns_zone_id
  dns_certificate_arn_regional = local.dns_certificate_arn_regional
}