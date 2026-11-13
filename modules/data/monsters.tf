/*
  Monsters data structure definition:

  Each monster is served at GET /<name>, from one DynamoDB table per name list,
  and documented under its own tag in the Swagger docs. Adding a monster is one
  entry here plus its seed files.

  Each object requires:
  - name (string): Route and table name stem (e.g. "goblin" is served at GET /goblin)
  - description (string): The naming theme, shown as the monster's tag in the Swagger docs
  - first_names_path (string): JSON array of first names, relative to the environment root

  Optional fields:
  - last_names_path (string): JSON array of last names, relative to the environment root (default: null, first names only)

  Constraints:
  - name must be unique and lowercase
  - Each name list becomes a table in dynamodb_tables, named <name>-first-name or <name>-last-name

  Example:
  {
    name             = "goblin"
    description      = "Names themed on washed out wrestlers/average blokes"
    first_names_path = "../../application/seed_data/goblin-first-name.json"
    last_names_path  = "../../application/seed_data/goblin-last-name.json"
  }
*/

locals {
  monsters = [
    {
      name             = "goatmen"
      description      = "Names themed on cute fluffy animals"
      first_names_path = "../../application/seed_data/goatmen-first-name.json"
    },
    {
      name             = "goblin"
      description      = "Names themed on washed out wrestlers/average blokes"
      first_names_path = "../../application/seed_data/goblin-first-name.json"
      last_names_path  = "../../application/seed_data/goblin-last-name.json"
    },
    {
      name             = "ogre"
      description      = "Names themed on cavemen like speech"
      first_names_path = "../../application/seed_data/ogre-first-name.json"
    },
    {
      name             = "orc"
      description      = "Names themed on {noun} + {silly moniker}"
      first_names_path = "../../application/seed_data/orc-first-name.json"
      last_names_path  = "../../application/seed_data/orc-last-name.json"
    },
    {
      name             = "skeleton"
      description      = "Names themed on 18th Century British Gentlemen"
      first_names_path = "../../application/seed_data/skeleton-first-name.json"
      last_names_path  = "../../application/seed_data/skeleton-last-name.json"
    },
    {
      name             = "troll"
      description      = "Names themed on a Scandinavian twist"
      first_names_path = "../../application/seed_data/troll-first-name.json"
      last_names_path  = "../../application/seed_data/troll-last-name.json"
    }
  ]
}
