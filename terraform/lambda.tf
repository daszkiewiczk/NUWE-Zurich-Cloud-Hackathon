data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "src/update_clients_table.py"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "update_clients_table" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda.zip"
  function_name = "update-clients-table"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "update_clients_table.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.10"

  memory_size = 10240
  timeout = 900

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_s3_bucket_notification" "clients" {
  bucket = aws_s3_bucket.clients.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.update_clients_table.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = "client_data.json"
  }

  depends_on = [aws_lambda_permission.s3_permission_to_trigger_lambda]
}


resource "aws_lambda_permission" "s3_permission_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_clients_table.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.clients.arn
}
