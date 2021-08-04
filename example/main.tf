variable "aws_account" {}
variable "completion_redirect_url" {}
variable "google_recaptcha_secret" {}
variable "pardot_form_handler_url" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.52.0"
    }
  }

  backend "s3" {
    bucket = "pardot-form-handler-terraform-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"

  allowed_account_ids = [var.aws_account]
}

// Handler
module "pardot-form-handler" {
  source                  = "../"
  completion_redirect_url = var.completion_redirect_url
  google_recaptcha_secret = var.google_recaptcha_secret
  pardot_form_handler_url = var.pardot_form_handler_url
  aws_account             = var.aws_account
}