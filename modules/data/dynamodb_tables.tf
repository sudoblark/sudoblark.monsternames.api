/*
  DynamoDB Tables data structure definition:

  Each object requires:
  - name (string): Short name for the table (auto-prefixed with aws-sudoblark-production-monsternames-api)
  - hash_key (string): Partition key attribute name, stored as a string

  Optional fields:
  - seed_data_path (string): JSON array of hash key values to write as items, relative to the environment root (default: null, no items)

  Constraints:
  - Full table name must be 3-255 characters of a-z, A-Z, 0-9, _, - and .
  - Tables are PAY_PER_REQUEST, with point-in-time recovery and AWS-managed encryption
  - Terraform owns every seeded item, so editing the JSON file edits the table

  Example:
  {
    name           = "goblin-first-name"
    hash_key       = "value"
    seed_data_path = "../../application/seed_data/goblin-first-name.json"
  }
*/

locals {
  dynamodb_tables = [
    {
      name           = "goatmen-first-name"
      hash_key       = "value"
      seed_data_path = "../../application/seed_data/goatmen-first-name.json"
    },
    {
      name           = "goblin-first-name"
      hash_key       = "value"
      seed_data_path = "../../application/seed_data/goblin-first-name.json"
    },
    {
      name           = "goblin-last-name"
      hash_key       = "value"
      seed_data_path = "../../application/seed_data/goblin-last-name.json"
    },
    {
      name           = "ogre-first-name"
      hash_key       = "value"
      seed_data_path = "../../application/seed_data/ogre-first-name.json"
    },
    {
      name           = "orc-first-name"
      hash_key       = "value"
      seed_data_path = "../../application/seed_data/orc-first-name.json"
    },
    {
      name           = "orc-last-name"
      hash_key       = "value"
      seed_data_path = "../../application/seed_data/orc-last-name.json"
    },
    {
      name           = "skeleton-first-name"
      hash_key       = "value"
      seed_data_path = "../../application/seed_data/skeleton-first-name.json"
    },
    {
      name           = "skeleton-last-name"
      hash_key       = "value"
      seed_data_path = "../../application/seed_data/skeleton-last-name.json"
    },
    {
      name           = "troll-first-name"
      hash_key       = "value"
      seed_data_path = "../../application/seed_data/troll-first-name.json"
    },
    {
      name           = "troll-last-name"
      hash_key       = "value"
      seed_data_path = "../../application/seed_data/troll-last-name.json"
    }
  ]
}
