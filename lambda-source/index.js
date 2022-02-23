'use strict'
let axios = require('axios');

const FORM_HANDLER = process.env.PARDOT_FORM_HANDLER_URL
const RECAPTCHA_SECRET = process.env.RECAPTCHA_SECRET
const REDIRECT_URL = process.env.REDIRECT_URL

async function post(url, payload, opts) {
  return axios.post(url, payload, { ...opts })
}

async function verifyRecaptcha(captchaResponse) {
  try {
    const body = new URLSearchParams();
    body.append("secret", RECAPTCHA_SECRET);
    body.append("response", captchaResponse);

    const response = await post(
      'https://www.google.com/recaptcha/api/siteverify', 
      body,
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded"
        }
      }
    )
    console.log("Captcha Result: ", response);
    const { data } = response;

    if (!data || !data.success) {
      console.error("Invalid Recaptcha");
      return false;
    }

    return data;
  } catch (err) {
    console.error("Recaptcha Failure: ", err);
    return false;
  }
}

async function sendForm(formPayload) {
  try {
    // Does the `data` response here never need to get back to the user?
    const data = await post(
      FORM_HANDLER, 
      formPayload, 
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          'Access-Control-Allow-Origin': '*',
        },
        params: {
          success_location: REDIRECT_URL,
          error_location: REDIRECT_URL
        }
      }
    )
    return data;
  } catch (err) {
    console.error("Form Error: ", err);
    return false;
  }
}

const Responses = {
  Unauthorized: () => ({ statusCode: 401 }),
  BadRequest: () => ({ statusCode: 400 }),
  Redirect: (Location) => ({ statusCode: 302, headers: { Location }})
}

async function proxyForm(event, _context) {
  const buff = Buffer.from(event.body, 'base64');
  const text = buff.toString('ascii');
  const recaptchaPair = text.split('&').find(pair => pair.startsWith('g-recaptcha-response'));
  
  if (!recaptchaPair) {
    // reCaptcha not provided at all
    // maybe bad request?
    return Errors.Unauthorized()
  }
  
  const [_key, captchaResponse] = recaptchaPair.split("=");
  console.log("Provided reCaptcha value:", captchaResponse)
  
  const isRecaptchaValid = await verifyRecaptcha(captchaResponse);
  if (!isRecaptchaValid) {
    return Errors.Unauthorized()
  }

  const formResponse = await sendForm(text);
  if (!formResponse) {
    return Errors.BadRequest()
  }

  return Responses.Redirect(REDIRECT_URL);
}

exports.handler = async function handler(event, context) {
  console.log("Full event body", event.body);
  return proxyForm(event, context);
};
