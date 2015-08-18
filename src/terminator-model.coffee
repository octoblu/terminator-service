_       = require 'lodash'
async   = require 'async'
{exec}  = require 'child_process'
request = require 'request'
debug   = require('debug')('terminator-service:terminator-model')

class TerminatorModel
  constructor: (@message, dependencies={}) ->
    debug '.new', @message
    @AWS = dependencies.AWS ? require 'aws-sdk'
    @ipRegEx = /ip-((\d+)-(\d+)-(\d+)-(\d+))/
    @ec2 = new @AWS.EC2()

  terminate: (callback=->) =>
    @_findIp (error, ip) =>
      return callback error if error?
      return callback() unless ip?
      debug 'terminate ip', ip
      @_terminate ip, (error) =>
        return callback error if error?
        callback()

  _findInstance: (ip, callback=->) =>
    params =
      Filters:
        [
          Name: 'private-ip-address'
          Values: [ip]
        ]
    @ec2.describeInstances params, (error, data) =>
      return callback error if error?
      callback null, data?.Reservations?[0]?.Instances?[0]?.InstanceId

  _findIp: (callback=->) =>
    matches = @message.match @ipRegEx
    callback null, matches?[1].replace /-/g, '.'

  _terminate: (ip, callback=->) =>
    @_findInstance ip, (error, instanceId) =>
      return callback error if error?
      debug 'found instance', instanceId

      @_terminateInstance instanceId, (error) =>
        return callback error if error?
        callback()

  _terminateInstance: (instanceId, callback=->) =>
    params =
      InstanceIds: [@instanceId]

    debug 'rebooting instance', instanceId
    @ec2.rebootInstances params, (error) =>
      return callback error if error?
      callback()

module.exports = TerminatorModel
