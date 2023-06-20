resource "aws_dynamodb_table" "clients" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  # read_capacity  = var.dynamodb_table_read_capacity
  # write_capacity = var.dynamodb_table_write_capacity
  hash_key       = var.dynamodb_table_hash_key
  range_key      = var.dynamodb_table_range_key

  attribute {
    name = "id"
    type = "S"
  }


  attribute {
    name = "plate"
    type = "S"
  }


  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  # global_secondary_index {
  #   name               = "GameTitleIndex"
  #   hash_key           = "GameTitle"
  #   range_key          = "TopScore"
  #   write_capacity     = 10
  #   read_capacity      = 10
  #   projection_type    = "INCLUDE"
  #   non_key_attributes = ["UserId"]
  # }

  tags = {
    Name        = "Clients"
    Environment = "development"
  }
  
  # replica {
  #   region_name = "us-east-2"
  # }

  # replica {
  #   region_name = "us-west-2"
  # }
}