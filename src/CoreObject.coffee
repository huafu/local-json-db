EventEmitter = require('events').EventEmitter
utils = require './utils'

Class = null

# Base for all objects
#
# @since 0.0.2
# @example
#   class MyClass extends CoreObject
#     # ...
class CoreObject extends EventEmitter
  # Get the name of the class
  #
  # @since 0.0.2
  # @return {String} name of the class
  @className: -> @toString().match(/function\s+([a-zA-Z0-9_]+)/)[1]


  # Log a string with the class name as a prefix
  #
  # @overload log(level, items...)
  #   @since 0.0.2
  #   @param {String} level     level (debug, notice, info, warning, error, danger or fatal)
  #   @param {Object} items...  anything to give back to the logger
  #   @return {CoreObject}      this object for chaining
  #
  # @overload log(items...)
  #   @since 0.0.2
  #   @param {Object} items...  anything to give back to the logger
  #   @return {CoreObject}      this object for chaining
  @log: (level, items...) ->
    unless level in ['debug', 'notice', 'info', 'warning', 'error', 'danger', 'fatal']
      items.unshift level
      level = 'debug'
    utils.log "[#{@className()}#{if arguments.callee.caller is @:: log then '#' else '.'}log][#{level}]", items...
    @


  # Make an assertion and throw an error if it fails
  #
  # @since 0.0.2
  # @param {Boolean} expression the test to assert true
  # @return {CoreObject}        this object for chaining
  @assert: (expression, message) ->
    unless expression
      utils.throw "[#{@className()}#{if arguments.callee.caller is @:: assert then '#' else '.'}assert] #{ message }"
    @


  # Lock given properties so that setting them will fail
  #
  # @since 0.0.2
  # @param {String} names...  the name of each property to lock
  # @return {CoreObject}      this class for chaining
  @lockProperties: (names...) ->
    for name in names
      utils.lock(@, name)
    @


  # Returns the name of the class for this object
  #
  # @since 0.0.2
  # @return {String} class name of this object
  className: ->
    @constructor.className()


  # Log a some data
  #
  # @since 0.0.2
  # @see {CoreObject.log}
  log: (level, items...) ->
    @constructor.log arguments...
    @


  # Make an assertion, throwing an error in case of failure
  #
  # @since 0.0.2
  # @see {CoreObject.assert}
  assert: (expression, message) ->
    @constructor.assert arguments...
    @


  # Lock properties of this object to disallow changing them later
  #
  # @since 0.0.2
  # @see {CoreObject.lockProperties}
  # @param {String} names...  the name of each property to lock
  # @return {CoreObject}      this object for chaining
  lockProperties: (names...) ->
    for name in names
      utils.lock(@, name)
    @


  # Get the UUID of the object or fail if none defined
  #
  # @since 0.0.2
  # @return {String} UUID of the object
  uuid: ->
    @assert (@_uuid and typeof @_uuid is 'string'), "undefined #{ @className() }#_uuid or not a string"
    @_uuid


  # Get a string identification of the object
  #
  # @since 0.0.2
  # @return {String} the string identifying the object
  identify: ->
    "[object #{ @className() }<#{ @uuid() }>]"


  # Used to destroy the object
  #
  # @since 0.0.2
  destroy: ->


module.exports = Class = CoreObject
