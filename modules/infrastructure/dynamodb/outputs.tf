output "tables" {
  description = "Map of created DynamoDB tables with their attributes"
  value = {
    for name, table in aws_dynamodb_table.table : name => {
      id         = table.id
      arn        = table.arn
      name       = table.name
      item_count = length([for item in local.items : item if item.table_name == name])
    }
  }
}

output "table_arns" {
  description = "Map of table names to ARNs"
  value = {
    for name, table in aws_dynamodb_table.table : name => table.arn
  }
}
