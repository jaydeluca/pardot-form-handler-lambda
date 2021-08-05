variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account" {
  description = "AWS Account ID"
  type        = string
}

variable "function_name" {
  description = "Name of the lambda function"
  type        = string
  default     = "pardot-email-handler"
}

variable "pardot_form_handler_url" {
  description = "URL of the pardot form handler provided by pardot."
  type        = string
}

variable "google_recaptcha_secret" {
  description = "Recaptcha secret provided by google."
  type        = string
}

variable "completion_redirect_url" {
  description = "URL of where to redirect the user to after processing the submission."
  type        = string
}

variable "allowed_submission_origins" {
  description = "Origins to allow submissions from"
  type        = list(string)
  default     = ["*"]
}