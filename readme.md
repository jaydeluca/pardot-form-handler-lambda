# Pardot Form Handler Lambda
The purpose of this project is to create a lambda function behind an api gateway endpoint that a form can submit to, which 
will perform captcha and any other validation prior to forwarding along to the pardot form handler endpoint. This also 
allows hiding the pardot endpoint so bots cannot submit directly to pardot.