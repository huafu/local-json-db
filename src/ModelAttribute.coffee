utils = require './utils'
CoreObject = require './CoreObject'
Model = require './Model'


Class = null

###*
  Holds the attribute descriptor of a model

  @since 0.0.7
  @class ModelAttribute
  @extends CoreObject
  @constructor
###
class ModelAttribute extends CoreObject
  ###*
    The model holding this attribute
    @since 0.0.7
    @private
    @property _model
    @type Model
  ###
  _model: null
  ###*
    Name of this attribute
    @since 0.0.7
    @private
    @property _name
    @type String
  ###
  _name: null
  ###*
    Type of this attribute
    @since 0.0.7
    @private
    @property _type
    @type String
    @default "string"
  ###
  _type: null


  ###*
    Constructs a model attribute

    @since 0.0.7
    @method constructor
    @param {Model} model The model holding the attribute
    @param {String} name The name of the attribute in the model
    @param {String} type The type of the attribute
  ###
  constructor: (model, name, type = 'string') ->
    @assert model and model instanceof Model, "given model must be an instance of Model"
    @assert(
      name and utils.isString(name) and /^[a-z_][a-z0-9_]*$/i.test(name),
      "given name must be a string with alphanumeric characters"
    )
    @assert type and utils.isString(type) and type.length, "type must be a string of at least 1 char"
    @_model = model
    @_name = name
    @_type = type


  ###*
    Serialize a value depending on the attribute type

    @since 0.0.7
    @method serialize
    @param {mixed} value The value to serialize
    @return {mixed} The serialized value
  ###
  serialize: (value) ->
    if value? and @_type isnt 'mixed'
      switch @_type
        when 'string', 'str' then "#{ value }"
        when 'number', 'num' then Number(value)
        when 'boolean', 'bool' then Boolean(value)
        when 'date'
          if value instanceof Date
            value.toISOString()
          else
            (new Date value).toISOString()
        else
          @assert no, "unknown type: #{ @_type }"
    else
      value


  ###*
    Deserialize a value depending on the attribute type

    @since 0.0.7
    @method deserialize
    @param {mixed} value The value to deserialize
    @return {mixed} The deserialized value
  ###
  deserialize: (value) ->
    if value? and @_type isnt 'mixed'
      switch @_type
        when 'string', 'str' then "#{ value }"
        when 'number', 'num' then Number(value)
        when 'boolean', 'bool' then Boolean(value)
        when 'date'
          if value instanceof Date
            value
          else
            new Date value
        else
          @assert no, "unknown type: #{ @_type }"
    else
      value


  # @see {CoreObject.uuid}
  uuid: ->
    "#{ @_model.uuid() }.#{ @_name }"


module.exports = Class = ModelAttribute
