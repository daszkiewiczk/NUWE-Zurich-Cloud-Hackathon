resource "aws_dynamodb_table" "clients" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.dynamodb_table_hash_key
  range_key    = var.dynamodb_table_range_key

  stream_enabled = true

  attribute {
    name = var.dynamodb_table_hash_key
    type = "S"
  }

  attribute {
    name = var.dynamodb_table_range_key
    type = "S"
  }

  replica {
    region_name = "us-east-2"
  }

  replica {
    region_name = "us-west-2"
  }
}