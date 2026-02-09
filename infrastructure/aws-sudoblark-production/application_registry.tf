# Application Registry for service discovery and resource grouping
resource "aws_servicecatalogappregistry_application" "application" {
  provider = aws.applicationRegistry

  name        = "aws-sudoblark-production-monsternames-api"
  description = "Monster Names API - REST API for generating pseudo-random fantasy monster names"
}