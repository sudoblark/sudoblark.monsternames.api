# Terraform configuration
terraform {
  required_version = "~> 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }

  }
  backend "s3" {
    bucket = "aws-sudoblark-production-terraform-state"
    key    = "aws/aws-sudoblark-production/sudoblark.monsternames.api/terraform.tfstate"
    # Enable server side encryption for the state file
    encrypt = true
    region  = "eu-west-2"
    assume_role = {
      role_arn     = "arn:aws:iam::157658492476:role/aws-sudoblark-production-github-cicd-role"
      session_name = "sudoblark.terraform.modularised-demo"
      external_id  = "CI_CD_PLATFORM"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
  alias  = "applicationRegistry"

  assume_role {
    role_arn     = "arn:aws:iam::157658492476:role/aws-sudoblark-production-github-cicd-role"
    session_name = "sudoblark.terraform.modularised-demo"
    external_id  = "CI_CD_PLATFORM"
  }

  default_tags {
    tags = {
      environment = "production"
      managed_by  = "sudoblark.monsternames.api"
    }
  }
}

provider "aws" {
  region = "eu-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::157658492476:role/aws-sudoblark-production-github-cicd-role"
    session_name = "sudoblark.terraform.modularised-demo"
    external_id  = "CI_CD_PLATFORM"
  }

  default_tags {
    tags = merge({
      environment = "production"
      managed_by  = "sudoblark.monsternames.api"
      }, aws_servicecatalogappregistry_application.demo.tags
    )
  }
}
