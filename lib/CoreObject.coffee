EventEmitter = require('events').EventEmitter
utils = require './utils'


class CoreObject extends EventEmitter
  @className: -> @toString().match(/function\s+([a-zA-Z0-9_]+)/)[1]

  @log: (level, items...) ->
    unless level in ['debug', 'notice', 'info', 'warning', 'error', 'danger', 'fatal']
      items.unshift level
      level = 'debug'
    utils.log "[#{@className()}#{if arguments.callee.caller is @:: log then '#' else '.'}log][#{level}]", items...
    @

  @assert: (expression, message) ->
    unless expression
      utils.throw "[#{@className()}#{if arguments.callee.caller is @:: assert then '#' else '.'}assert] #{ message }"
    @

  @lockProperties: (names...) ->
    for name in names
      utils.lock(@, name)
    @

  className: ->
    @constructor.className()

  log: (level, items...) ->
    @constructor.log arguments...
    @

  assert: (expression, message) ->
    @constructor.assert arguments...
    @

  lockProperties: (names...) ->
    for name in names
      utils.lock(@, name)
    @

  uuid: ->
    @assert (@_uuid and typeof @_uuid is 'string'), "undefined #{ @className() }#_uuid or not a string"
    @_uuid


  identify: ->
    "[object #{ @className() }<#{ @uuid() }>]"


module.exports = CoreObject
