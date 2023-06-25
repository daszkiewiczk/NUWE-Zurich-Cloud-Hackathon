resource "aws_s3_bucket" "clients" {
  bucket_prefix = var.bucket_name

  force_destroy = var.stage == "local" ? true : false
}

resource "aws_s3_bucket_versioning" "clients_versioning" {
  bucket = aws_s3_bucket.clients.id
  versioning_configuration {
    status = "Enabled"
  }
}