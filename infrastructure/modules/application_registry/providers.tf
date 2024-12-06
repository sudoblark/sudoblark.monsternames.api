terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.61.0"
      configuration_aliases = [aws.applicationRegistry]
    }
  }
}