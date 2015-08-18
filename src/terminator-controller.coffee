_            = require 'lodash'
debug        = require('debug')('terminator-service:terminator-controller')

class TerminatorController
  constructor: (dependencies={}) ->
    @TerminatorModel = dependencies.TerminatorModel || require './terminator-model'

  terminate: (request, response) =>
    payload = JSON.parse request.body?.payload
    @terminatorModel = new @TerminatorModel payload?.event?.m
    @terminatorModel.terminate (error) ->
      return response.status(401).json(error: 'unauthorized') if error?.message == 'unauthorized'
      return response.status(502).send(error: error.message) if error?
      return response.status(201).end()

module.exports = TerminatorController
