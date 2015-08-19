cors = require 'cors'
morgan = require 'morgan'
express = require 'express'
bodyParser = require 'body-parser'
meshbluAuth = require 'express-meshblu-auth'
MeshbluConfig = require 'meshblu-config'
errorHandler = require 'errorhandler'
LogentriesWebhookAuthExpress = require 'express-logentries-webhook-auth'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
TerminatorController = require './src/terminator-controller'

PORT = process.env.PORT ? 80

meshbluConfig = new MeshbluConfig().toJSON()

setRawBody = (req, res, buf) =>
  req.rawBody = buf

app = express()
app.use cors()
app.use morgan('combined')
app.use errorHandler()
app.use meshbluHealthcheck()
app.use bodyParser.urlencoded limit: '50mb', extended : true, verify: setRawBody
app.use bodyParser.json limit : '50mb', verify: setRawBody
app.use LogentriesWebhookAuthExpress password: meshbluConfig.token, bodyParam: 'rawBody'

app.options '*', cors()

terminatorController = new TerminatorController

app.post '/terminate', terminatorController.terminate
app.post '/replicate', terminatorController.replicate

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"
