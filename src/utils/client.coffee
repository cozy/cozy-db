# create client
request = require 'request-json-light'
client = request.newClient 'http://localhost:9101'

# DS token
if process.env.NODE_ENV in ["production","test"]
    client.setBasicAuth process.env.NAME, process.env.TOKEN
else
    client.setBasicAuth Math.random().toString(36), "token"

module.exports = client