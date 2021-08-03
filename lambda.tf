# Lambda
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

