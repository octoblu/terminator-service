cors = require 'cors'
morgan = require 'morgan'
express = require 'express'
bodyParser = require 'body-parser'
meshbluAuth = require 'express-meshblu-auth'
errorHandler = require 'errorhandler'
MeshbluConfig = require 'meshblu-config'
MeshbluAuthExpress = require 'express-meshblu-auth/src/meshblu-auth-express'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
TerminatorController = require './src/terminator-controller'

PORT = process.env.PORT ? 80

app = express()
app.use cors()
app.use morgan('combined')
app.use errorHandler()
app.use meshbluHealthcheck()
app.use bodyParser.urlencoded limit: '50mb', extended : true
app.use bodyParser.json limit : '50mb'

meshbluConfig = new MeshbluConfig().toJSON()
app.use meshbluAuth meshbluConfig

app.options '*', cors()

terminatorController = new TerminatorController

app.post '/terminate', terminatorController.deploy

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"
