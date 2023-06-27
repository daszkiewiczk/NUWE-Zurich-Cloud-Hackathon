resource "aws_dynamodb_table" "clients" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.dynamodb_table_hash_key
  range_key    = var.dynamodb_table_range_key

  global_secondary_index {
    name            = "plateIndex"
    hash_key        = "plate"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "nameIndex"
    hash_key        = "surname"
    range_key       = "name"
    projection_type = "ALL"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = var.dynamodb_table_hash_key
    type = "S"
  }

  attribute {
    name = var.dynamodb_table_range_key
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }

  attribute {
    name = "surname"
    type = "S"
  }

  replica {
    region_name = "us-east-2"
  }

  replica {
    region_name = "us-west-2"
  }
}