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

# dependencies are packaged with lambda function itself as a workaround for LocalStack not supporting Lambda layers in the community version
resource "null_resource" "install_python_dependencies" {
  triggers = {
    shell_hash = "${sha256(file("${path.module}/src/requirements.txt"))}"
  }
  provisioner "local-exec" {
    command = "bash ${path.module}/util/install_lambda_dependencies.sh"

    environment = {
      lambda_name = var.lambda_name
      path_module = path.module
      runtime = var.runtime
    }
  }
}

data "archive_file" "lambda" {
  depends_on = [null_resource.install_python_dependencies]
  type        = "zip"
  source_dir   = "${path.module}/src"
  output_path = "${var.lambda_name}.zip"
}


resource "aws_lambda_function" "update_clients_table" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${var.lambda_name}.zip"
  function_name = "${var.lambda_name}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "${var.lambda_name}.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  # runtime = "python3.10"
  runtime = "python${var.runtime}"

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
