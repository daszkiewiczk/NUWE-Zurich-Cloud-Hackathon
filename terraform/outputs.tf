output "bucket_name" {
  value = aws_s3_bucket.clients.bucket
}

output "table_name" {
  value = aws_dynamodb_table.clients.name
}