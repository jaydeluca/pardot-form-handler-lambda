// Handler
module "pardot-form-handler" {
  source                  = "../"
  completion_redirect_url = var.completion_redirect_url
  google_recaptcha_secret = var.google_recaptcha_secret
  pardot_form_handler_url = var.pardot_form_handler_url
  aws_account             = var.aws_account
}