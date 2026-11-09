resource "aws_dynamodb_table" "table" {
  for_each = local.tables_map

  name         = each.value.full_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = each.value.hash_key

  attribute {
    name = each.value.hash_key
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = each.value.full_name
  }
}

# Seed items, one per value in the table's seed data
resource "aws_dynamodb_table_item" "item" {
  for_each = local.items_map

  table_name = aws_dynamodb_table.table[each.value.table_name].name
  hash_key   = aws_dynamodb_table.table[each.value.table_name].hash_key

  item = jsonencode({
    (each.value.hash_key) = { S = each.value.value }
  })
}
