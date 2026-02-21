terraform {
  required_version = "~> 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

data "aws_caller_identity" "current_account" {}

data "aws_region" "current_region" {}

# Remote state data source for DNS wildcard certificates
# Reads from sudoblark.dns infrastructure state
data "terraform_remote_state" "dns" {
  backend = "s3"
  
  config = {
    bucket = "aws-sudoblark-production-terraform-state"
    key    = "dns/terraform.tfstate"
    region = "eu-west-2"
  }
}
