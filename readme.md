# Pardot Form Handler Lambda
The purpose of this project is to create a lambda function behind an api gateway endpoint that a form can submit to, which 
will perform captcha and any other validation prior to forwarding along to the pardot form handler endpoint. This also 
allows hiding the pardot endpoint so bots cannot submit directly to pardot.

## Why?
- Pardot form handlers do not have any captcha integrations, and spam bots have no problem bypassing client-side validation
- Pardot form handlers do not allow any control over request origin (CORS), so if a bot inspects your form and identifies the pardot 
form url, they can submit directly, bypassing your form and any validation entirely.


## Usage
Clone and reference the module in your TF:
```hcl-terraform
module "pardot-form-handler" {
  source                     = "/location/of/module"
  aws_account                = "1234567890"
  
  // get this from google, implement captcha into your form client-side
  google_recaptcha_secret    = "6LeSyY0UAdaAADGdizS1ouhd23U1SsE4LhKwF8UGC7"

  // provided by pardot
  pardot_form_handler_url    = "https://pardot.com/my-form-handler-url"

  // where to redirect user after submission
  completion_redirect_url    = "https://mysite.com/completed-form-landing-page"

  // optional, will default to allow from all ("*") if not set
  allowed_submission_origins = ["https://mysite.com"]

  // optional, defaults to 5
  timeout                    = 10
}
```

If you make changes to the lambda function source dependencies (`lambda-source/package.json`), be sure to rebuild prior to applying the terraform so that it is included 
in the zip file
```bash
// run from inside the lambda-source directory
yarn install
```

Ensure you include [captcha](https://www.google.com/recaptcha/about/) in your form and set your `action` to your api gateway resource:
```html
<form method="POST" action="https://vpopxndhik.execute-api.us-east-1.amazonaws.com/pardot_lambda_stage/">
  <!-- Make sure your form includes all required inputs configured in your pardot backend -->
  <input type="text" name="name" id="email" placeholder="Email" required />
  <input type="text" name="name" id="name" placeholder="Name" required />

  <!-- Provided by google -->
  <div class="g-recaptcha" data-sitekey="6LerFZQbAAAM_mmg_J-OpkffuI0Uv10topj"></div>

  <input type="submit" value="Submit">
</form>
```