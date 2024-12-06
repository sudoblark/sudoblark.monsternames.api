resource "aws_servicecatalogappregistry_application" "monsternames" {
  provider = aws.applicationRegistry
  name     = lower("${var.environment}-${var.application_name}-application")
}