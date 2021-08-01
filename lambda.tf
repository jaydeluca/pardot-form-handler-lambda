data "archive_file" "lambda_source" {
  type = "zip"

  source_dir  = "${path.module}/lambda-source"
  output_path = "${path.module}/lambda-source/lambda-source.zip"
}

resource "aws_lambda_function" "pardot_form_handler" {
  function_name = var.function_name

  role             = aws_iam_role.pardot_form_handler_role.arn
  handler          = "index.test"
  runtime          = "nodejs14.x"
  source_code_hash = data.archive_file.lambda_source.output_base64sha256

  environment {
    variables = {
      PARDOT_FORM_HANDLER_URL = var.function_name,
      RECAPTCHA_SECRET = var.google_recaptcha_secret,
      REDIRECT_URL = var.completion_redirect_url
    }
  }
}