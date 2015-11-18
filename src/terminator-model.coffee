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
    @autoScaling = new @AWS.AutoScaling()

  replicate: (callback=->) =>
    @_findIp (error, ip) =>
      return callback error if error?
      return callback() unless ip?
      debug 'terminate ip', ip
      @_replicate ip, (error) =>
        return callback error if error?

        @_terminate ip, (error) =>
          return callback error if error?
          callback()

  terminate: (callback=->) =>
    @_findIp (error, ip) =>
      return callback error if error?
      return callback() unless ip?
      debug 'terminate ip', ip
      @_terminate ip, (error) =>
        return callback error if error?
        callback()

  reboot: (callback=->) =>
    @_findIp (error, ip) =>
      return callback error if error?
      return callback() unless ip?
      debug 'reboot ip', ip
      @_reboot ip, (error) =>
        return callback error if error?
        callback()

  _adjustAutoScalingGroup: (group, callback=->) =>
    @_getAutoScalingMinSize group, (error, minSize) =>
      return callback error if error?
      return callback new Error('No MinSize') unless minSize?

      params =
        AutoScalingGroupName: group
        MinSize: minSize + 1

      debug 'updateAutoScalingGroup', params
      @autoScaling.updateAutoScalingGroup params, (error) =>
        return callback error if error?
        callback()

  _getAutoScalingMinSize: (group, callback=->) =>
    params =
      AutoScalingGroupNames: [group]

    @autoScaling.describeAutoScalingGroups params, (error, data) =>
      return callback error if error?
      callback null, data?.AutoScalingGroups?[0]?.MinSize

  _findInstance: (ip, callback=->) =>
    params =
      Filters:
        [
          Name: 'private-ip-address'
          Values: [ip]
        ]
    @ec2.describeInstances params, (error, data) =>
      return callback error if error?
      callback null, data?.Reservations?[0]?.Instances?[0]

  _findIp: (callback=->) =>
    matches = @message.match @ipRegEx
    callback null, matches?[1].replace /-/g, '.'

  _reboot: (ip, callback=->) =>
    @_findInstance ip, (error, instance) =>
      return callback error if error?
      debug 'found instance', instance

      @_rebootInstance instance?.InstanceId, (error) =>
        return callback error if error?
        callback()

  _rebootInstance: (instanceId, callback=->) =>
    params =
      InstanceIds: [instanceId]
      DryRun: false

    debug 'rebooting instance', instanceId
    @ec2.rebootInstances params, (error) =>
      return callback error if error?
      callback()

  _replicate: (ip, callback=->) =>
    @_findInstance ip, (error, instance) =>
      return callback error if error?
      debug 'found instance', instance?.InstanceId

      autoscaling = _.findWhere instance?.Tags, Key: 'aws:autoscaling:groupName'
      return callback new Error('No Autoscaling Group Found') unless autoscaling?.Value

      @_adjustAutoScalingGroup autoscaling.Value, (error) =>
        return callback error if error?

        @_reboot ip, (error) =>
          return callback error if error?
          callback()

  _terminate: (ip, callback=->) =>
    @_findInstance ip, (error, instance) =>
      return callback error if error?
      debug 'found instance', instance?.InstanceId

      @_terminateInstance instance?.InstanceId, (error) =>
        return callback error if error?
        callback()

  _terminateInstance: (instanceId, callback=->) =>
    params =
      InstanceIds: [instanceId]
      DryRun: false

    debug 'terminating instance', instanceId
    @ec2.terminateInstances params, (error) =>
      return callback error if error?
      callback()

module.exports = TerminatorModel
