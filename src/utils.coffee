_ = require 'lodash'
_.mixin require 'underscore.inflections'


_.mixin(utils =
  copy: (object) ->
    _.cloneDeep object

  log: ->
    console.log arguments...

  throw: (Class, message) ->
    if arguments.length < 2
      message = Class
      Class = Error
    throw new Class(message)

  lock: (object, propertyName, enumerable = yes) ->
    val = object[propertyName]
    Object.defineProperty(object, propertyName, {
      get:          (-> val)
      set:          (-> utils.throw "property #{ propertyName } is read-only")
      configurable: no
      enumerable:   enumerable
    })
    object
)

module.exports = _
