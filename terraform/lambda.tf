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
  filename      = var.stage == "local" ? null : "${var.lambda_name}.zip"
  s3_bucket     = var.stage == "local" ? "hot-reload" : null
  s3_key        = var.stage == "local" ? "${abspath(path.module)}/src" : null
  function_name = "${var.lambda_name}"
  role          = aws_iam_role.role_for_lambda.arn
  handler       = "${var.lambda_name}.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python${var.runtime}"

  memory_size = 128
  timeout = 3

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
      HASH_KEY = var.dynamodb_table_hash_key
      SORT_KEY = var.dynamodb_table_range_key
    }
  }



}

resource "aws_s3_bucket_notification" "clients" {
  bucket = aws_s3_bucket.clients.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.update_clients_table.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = var.trigger_file
  }

  depends_on = [aws_lambda_permission.s3_permission_to_trigger_lambda]
}



