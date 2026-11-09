locals {
  # Create a map for efficient lookups
  tables_map = {
    for table in var.dynamodb_tables : table.name => table
  }

  # Flatten seed items so each value is its own table item
  items = flatten([
    for table in var.dynamodb_tables : [
      for value in table.items : {
        table_name = table.name
        hash_key   = table.hash_key
        value      = value
        key        = "${table.name}/${value}"
      }
    ]
  ])

  items_map = {
    for item in local.items : item.key => item
  }
}
