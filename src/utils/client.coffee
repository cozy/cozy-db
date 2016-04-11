# create client
request = require 'request-json-light'

# Data System's port is configurable
DS_PORT = process.env.DS_PORT or 9101
client = request.newClient "http://localhost:#{DS_PORT}"

# DS token
if process.env.NODE_ENV in ["production","test"]
    client.setBasicAuth process.env.NAME, process.env.TOKEN
else
    client.setBasicAuth Math.random().toString(36), "token"

module.exports = client

