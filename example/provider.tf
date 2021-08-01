terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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
  allowed_account_ids = var.allowed_account_ids
}