resource "aws_dynamodb_table" "clients" {
  name           = "clients"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"
  range_key      = "surname"

  attribute {
    name = "id"
    type = "S"
  }


  attribute {
    name = "surname"
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
  
  replica {
    region_name = "us-east-2"
  }

  replica {
    region_name = "us-west-2"
  }
}