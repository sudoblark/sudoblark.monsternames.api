# The module's input validation, with the AWS provider mocked.

mock_provider "aws" {}

variables {
  dynamodb_tables = [
    {
      name      = "goblin-first-name"
      full_name = "aws-sudoblark-production-monsternames-api-goblin-first-name"
      hash_key  = "value"
      items     = ["Bert", "Reggie"]
    }
  ]
}

run "accepts_a_valid_table" {
  command = plan
}

run "rejects_an_invalid_name" {
  command = plan

  variables {
    dynamodb_tables = [merge(var.dynamodb_tables[0], { full_name = "goblin first name" })]
  }

  expect_failures = [var.dynamodb_tables]
}

run "rejects_duplicate_seed_items" {
  command = plan

  variables {
    dynamodb_tables = [merge(var.dynamodb_tables[0], { items = ["Bert", "Bert"] })]
  }

  expect_failures = [var.dynamodb_tables]
}
