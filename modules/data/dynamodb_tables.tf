/*
  DynamoDB Tables data structure definition:

  Each monster in monsters.tf gets one table per name list, generated below.
  concat() any other tables onto the list.

  Each object requires:
  - name (string): Short name for the table (auto-prefixed with aws-sudoblark-production-monsternames-api)
  - hash_key (string): Partition key attribute name, stored as a string

  Optional fields:
  - seed_data_path (string): JSON array of hash key values to write as items, relative to the environment root (default: null, no items)

  Constraints:
  - Full table name must be 3-255 characters of a-z, A-Z, 0-9, _, - and .
  - Names must not clash with a derived <monster>-first-name or <monster>-last-name table
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
  # One table per monster name list in monsters.tf, named <monster>-first-name
  # or <monster>-last-name and seeded from the list's JSON file
  dynamodb_tables = flatten([
    for monster in local.monsters : [
      for field, path in {
        "first-name" = monster.first_names_path
        "last-name"  = try(monster.last_names_path, null)
        } : {
        name           = "${monster.name}-${field}"
        hash_key       = "value"
        seed_data_path = path
      } if path != null
    ]
  ])
}
