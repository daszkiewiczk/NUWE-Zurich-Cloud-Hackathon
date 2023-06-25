variable "lambda_name" {
  type    = string
  default = "update_clients_table"
}

variable "runtime" {
  type    = string
  default = "3.10"
}




variable "bucket_name" {
  type    = string
  default = "daszkiewiczk-clients"
}

variable "trigger_file" {
  type    = string
  default = "client_data.json"
}





variable "dynamodb_table_name" {
  type    = string
  default = "daszkiewiczk-clients"
}

variable "dynamodb_table_hash_key" {
  type    = string
  default = "id"
}

variable "dynamodb_table_range_key" {
  type    = string
  default = "plate"
}




variable "stage" {
  type    = string
  default = "local"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
 