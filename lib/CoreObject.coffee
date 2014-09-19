EventEmitter = require('events').EventEmitter

class CoreObject extends EventEmitter
  @__log:          -> console.log arguments...
  @__throw:        (message) -> throw new Error(message)
  @__lockProperty: (object, name) ->
    #console.log "locking `#{ name }`"
    val = object[name]
    object[name] = null
    delete object[name]
    Object.defineProperty(object, name, {
      get:          (-> val)
      set:          (-> CoreObject.__throw "property #{ name } is read-only")
      configurable: no
      enumerable:   yes
    })
    object

  @className: -> @toString().match(/function\s+([a-zA-Z0-9_]+)/)[1]

  @log: (level, items...) ->
    unless level in ['debug', 'notice', 'info', 'warning', 'error', 'danger', 'fatal']
      items.unshift level
      level = 'debug'
    CoreObject.__log "[#{@className()}#{if arguments.callee.caller is @:: log then '#' else '.'}log][#{level}]", items...

  @assert: (expression, message) ->
    unless expression
      CoreObject.__throw "[#{@className()}#{if arguments.callee.caller is @:: assert then '#' else '.'}assert] #{ message }"
    @

  @lockProperties: (names...) ->
    for name in names
      CoreObject.__lockProperty(@, name)
    @

  className: ->
    @constructor.className()

  log: (level, items...) ->
    @constructor.log arguments...

  assert: (expression, message) ->
    @constructor.assert arguments...

  lockProperties: (names...) ->
    for name in names
      CoreObject.__lockProperty(@, name)
    @

  uuid: ->
    @assert (@_uuid and typeof @_uuid is 'string'), "undefined #{ @className() }#_uuid or not a string"
    @_uuid


  identify: ->
    "[object #{ @className() }<#{ @uuid() }>]"

module.exports = CoreObject
