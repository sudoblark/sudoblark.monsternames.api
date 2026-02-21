# Data source to read DNS configuration from remote state
data "terraform_remote_state" "dns" {
  backend = "s3"

  config = {
    bucket = "aws-sudoblark-production-terraform-state"
    key    = "core/dns/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
    assume_role = {
      role_arn     = "arn:aws:iam::157658492476:role/aws-sudoblark-production-github-cicd-role"
      session_name = "sudoblark.terraform.modularised-demo"
      external_id  = "CI_CD_PLATFORM"
    }
  }

}

locals {
  dns_zone_id                    = data.terraform_remote_state.dns.outputs.hosted_zone.zone_id
  dns_certificate_arn_regional   = data.terraform_remote_state.dns.outputs.acm_certificate_arn_regional
  dns_certificate_arn_cloudfront = data.terraform_remote_state.dns.outputs.acm_certificate_arn_us_east_1
}
