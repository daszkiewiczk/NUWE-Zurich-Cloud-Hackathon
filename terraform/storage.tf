resource "aws_s3_bucket" "clients" {
  bucket_prefix = var.bucket_name
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.clients.id
  versioning_configuration {
    status = "Enabled"
  }
}

# resource "aws_kms_key" "incoming" {
#   description             = "Encryption Key for the S3 Bucket"
#   deletion_window_in_days = 7
# }

# resource "aws_kms_alias" "ingest" {
#   name          = "alias/${local.bucket_name}"
#   target_key_id = aws_kms_key.incoming.key_id
# }