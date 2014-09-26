utils = require './utils'
Model = require './Model'
ModelAttribute = require './ModelAttribute'
Relationship = require './Relationship'


Class = null

###*
  Extended model with pre-defined attributes and relations

  @since 0.0.7
  @class ModelEx
  @extends Model
  @constructor
###
class ModelEx extends Model
  ###*
    The attributes of this model
    @since 0.0.7
    @private
    @property _attributes
    @type Object<ModelAttribute>
  ###
  _attributes: null
  ###*
    The relations of this model
    @since 0.0.7
    @private
    @property _relationships
    @type Object<Relationship>
  ###
  _relationships: null
  ###*
    Whether the model is dynamic and accepts the addition of unknown attributes
    @since 0.0.7
    @private
    @property _isDynamic
    @type Boolean
    @default false
  ###
  _isDynamic: null
  ###*
    The database holding this model
    @since 0.0.7
    @private
    @property _database
    @type Database
  ###
  _database: null


  ###*
    Constructs a new extended model

    @since 0.0.7
    @method constructor
    @param {Database} database The database holding the model
    @param {Object} attributes The attribute definitions of the model
  ###
  constructor: (database, attributes = {'*': yes}) ->
    @assert(
      database and database instanceof Class._databaseClass(),
      "given database must be an instance of Database"
    )
    @assert(
      attributes.id is undefined,
      "attribute list cannot contain `id`, it's automatically added as attribute and used as the PK"
    )
    @_databse = database
    @_attributes = {}
    @_relationships = {}
    @_isDynamic = no
    for own name, type of attributes
      if name is '*'
        @_isDynamic = Boolean(type)
      else
        if type in 'str string num number bool boolean date mixed'.split(' ')
          @_attributes[name] = new ModelAttribute(@, name, type)
        else if type[0] is ':'
          @_relationships[name] = @_parseRelationship(name, type)
        else
          @assert no, "wrong attribute type: #{ type }"
    @lockProperties '_attributes', '_relationships', '_isDynamic', '_database'



  ###*
    Used to parse the definition of a relationship and return a Relationship object

    @since 0.0.7
    @private
    @method _parseRelationship
    @param {String} name Name of the attribute where the definition was found
    @return {Relationship} The relationship object
  ###
  _parseRelationship: (name, def) ->
    @assert(
      (m = def.match /^\s*\:([a-z_\-][a-z0-9_\-]*)(\[\])?(\s*@\s*([a-z_\-][a-z0-9_\-]*))?(\s*=>\s*([a-z_\-][a-z0-9_\-]*))?\s*$/i),
      "invalid relationship definition for #{ @_name }.#{ name }: #{ def }"
    )
    model = m[1]
    hasMany = m[2] is '[]'
    attr = m[4]
    invAccess = m[6]
    new Relationship(
      @_database,
      {
        model: @_name
        accessor: name
        attribute: attr
      },
      {
        model: model
        accessor: invAccess
      },
      hasMany
    )


module.exports = Class = ModelEx
