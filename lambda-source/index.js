'use strict'
let axios = require('axios');
let querystring = require('querystring');

const FORM_HANDLER = process.env.PARDOT_FORM_HANDLER_URL
const RECAPTCHA_SECRET = process.env.RECAPTCHA_SECRET
const REDIRECT_URL = process.env.REDIRECT_URL

const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': "Content-Type",
  "Access-Control-Allow-Methods": "OPTIONS,POST"
}

exports.handler = async (event, context, callback) => {
  console.log("Full event body", event.body);

  let buff = Buffer.from(event.body, 'base64');
  let text = buff.toString('ascii');

  var keyValuePairs = text.split('&');
  var json = {};

  console.log("Parsing form");
  for (var i = 0, len = keyValuePairs.length, tmp, key, value; i < len; i++) {
    tmp = keyValuePairs[i].split('=');
    key = decodeURIComponent(tmp[0]);
    value = decodeURIComponent(tmp[1]);
    if (key.search(/\[\]$/) != -1) {
      tmp = key.replace(/\[\]$/, '');
      json[tmp] = json[tmp] || [];
      json[tmp].push(value);
    } else {
      json[key] = value;
    }
    console.log(`${key}: ${value}`);
  }

  let captchaResponse = json["g-recaptcha-response"];
  console.log("Captcha Key: ", captchaResponse)

  try {
    const res = await axios.post('https://www.google.com/recaptcha/api/siteverify', querystring.stringify({
      secret: RECAPTCHA_SECRET,
      response: captchaResponse
    }), {
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      }
    })
    let result = await res.data
    console.log("Captcha Result: ", result)

    if (result.success) {
      const data = await axios.post(FORM_HANDLER, text, {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          'Access-Control-Allow-Origin': '*',
        },
        params: {
          success_location: REDIRECT_URL,
          error_location: REDIRECT_URL
        }
      })
    }
  } catch (err) {
    console.error("Error: ", err);
  }

  let redirectURL = REDIRECT_URL;
  var response = {
    "statusCode": 302,
    "headers": {
      Location: redirectURL,
    }
  };
  callback(null, response);
};