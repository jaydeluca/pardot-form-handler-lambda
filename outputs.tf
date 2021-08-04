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