data "aws_caller_identity" "current" {}

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

resource "aws_iam_role" "role_for_lambda" {
  name               = "${var.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "write_logs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.role_for_lambda.name
}

resource "aws_iam_role_policy" "lambda" {
  name = "${var.lambda_name}-policy"
  role = aws_iam_role.role_for_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:HeadObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.clients.bucket}/*",
        ]
      },
      {
        "Sid" : "DynamoDBTableModifyAccess",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:BatchWriteItem"
        ],
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}",
        ]
      }
    ]
  })
}




resource "aws_lambda_permission" "s3_permission_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_clients_table.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.clients.arn
}