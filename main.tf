locals {
  zip_name = "${var.function_name}.zip"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.52.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# IAM
resource "aws_iam_role" "pardot_form_handler_role" {
  name = "${var.function_name}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.pardot_form_handler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 for storing lambda
resource "aws_s3_bucket" "pardot_form_handler_lambda" {
  bucket = "${var.function_name}-lambda"

  acl           = "private"
  force_destroy = true
}

data "archive_file" "lambda_source" {
  type = "zip"

  source_dir  = "${path.module}/dist"
  output_path = "${path.module}/dist/${local.zip_name}"
}

resource "aws_s3_bucket_object" "pardot_lambda_source_object" {
  bucket = aws_s3_bucket.pardot_form_handler_lambda.id

  key    = "${local.zip_name}"
  source = data.archive_file.lambda_source.output_path

  etag = filemd5(data.archive_file.lambda_source.output_path)
}

# Lambda
resource "aws_lambda_function" "pardot_form_handler" {
  function_name = var.function_name

  s3_bucket = aws_s3_bucket.pardot_form_handler_lambda.id
  s3_key    = aws_s3_bucket_object.pardot_lambda_source_object.key

  role             = aws_iam_role.pardot_form_handler_role.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  source_code_hash = data.archive_file.lambda_source.output_base64sha256
  timeout          = var.timeout

  environment {
    variables = {
      PARDOT_FORM_HANDLER_URL = var.function_name,
      RECAPTCHA_SECRET        = var.google_recaptcha_secret,
      REDIRECT_URL            = var.completion_redirect_url
    }
  }
}


# API Gateway
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pardot_form_handler.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"

}

resource "aws_apigatewayv2_api" "lambda" {
  name          = "pardot_lambda_gateway"
  protocol_type = "HTTP"

  target = aws_lambda_function.pardot_form_handler.arn

  cors_configuration {
    allow_origins = var.allowed_submission_origins
  }
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "pardot_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.pardot_form_handler.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "pardot_form_handler" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.pardot_form_handler.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}


resource "aws_apigatewayv2_route" "pardot_form_handler" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /submit"
  target    = "integrations/${aws_apigatewayv2_integration.pardot_form_handler.id}"
}


# Cloudwatch
resource "aws_cloudwatch_log_group" "pardot_form_handler" {
  name = "/aws/lambda/${aws_lambda_function.pardot_form_handler.function_name}"

  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

# Outputs
output "lambda_bucket_name" {
  description = "Name of the S3 bucket used to store function code."

  value = aws_s3_bucket.pardot_form_handler_lambda.id
}

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.pardot_form_handler.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.lambda.invoke_url
}