utils = require './utils'
Model = require './Model'
ModelAttribute = require './ModelAttribute'
Relationship = require './Relationship'


Class = null

hasOwn = (o, p) -> {}.hasOwnProperty.call o, p

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
    Constructs a new extended model

    @since 0.0.7
    @method constructor
    @param {Database} database The database holding the model
    @param {String} name The name of our model
    @param {RecordStore} store Our store
    @param {Object} attributes The attribute definitions of the model
  ###
  constructor: (database, name, store, attributes = {'*': yes}) ->
    @assert database, "extended models must have a database defined"
    @assert name, "extended models must have a name defined"
    super
    @assert(
      attributes.id is undefined,
      "attribute list cannot contain `id`, it's automatically added as attribute and used as the PK"
    )
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
    for own prop, rel of @_relationships
      @assert(
        not @_attributes[rel.fromAttr()],
        "a relationship cannot be defined on an attribute of the model: #{ @_name }.#{ prop }"
      )
    @_store.setImporter @_importRecord.bind(@)
    @_store.setExporter @_exportRecord.bind(@)
    @lockProperties '_attributes', '_relationships', '_isDynamic'


  ###*
    Returns the known attributes of a model

    @since 0.0.7
    @method knownAttributes
    @param {Boolean} [includeRelationshipAttr=true] If `true` the attributes of relationships will be included
    @return {Array<String>} List of all known attributes
  ###
  knownAttributes: (includeRelationshipAttr = yes) ->
    res = ['id'].concat Object.keys(@_attributes)
    if includeRelationshipAttr
      for name, rel of @_relationships
        res.push rel.fromAttr()
    res


  ###*
    Finds whether the model is a dynamic model (unknown attributes aren't ignored)

    @since 0.0.7
    @method isDynamic
    @return {Boolean} Returns `true` if the model is dynamic, else `false`
  ###
  isDynamic: ->
    @_isDynamic


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


  ###*
    Export a record, transforming types and preparing relation accessors

    @since 0.0.7
    @private
    @method _exportRecord
    @param {Object} record The record to export
    @return {Object} The exported record
  ###
  _exportRecord: (record) ->
    if record?
      defined = ['id']
      for key, attr of @_attributes
        defined.push key
        record[key] = attr.deserialize(record[key])
      for key, rel of @_relationships
        defined.push rel.fromAttr()
        rel._setupRecord record
      #FIXME: should we delete undefined keys? pretty sure yes
      unless @_isDynamic
        for key, val of record when key not in defined
          delete record[key]
      #sign our record
      Object.defineProperty(record, '__modelName', {
        value: @_name
        writable: no
        configurable: no
        enumerable: no
      })
    record


  ###*
    Import a record, serializing its known attributes and relationships

    @since 0.0.7
    @private
    @method _importRecord
    @param {Object} record The record to import
    @return {Object} The serialized record
  ###
  _importRecord: (record) ->
    imported = ['id']
    rec = {}
    rec.id = record.id if record.id
    for key, rel of @_relationships
      attr = rel.fromAttr()
      if not hasOwn(record, attr) and hasOwn(record, key)
        rec[attr] = rel._serializeRelated record[key]
      else
        rec[attr] = record[attr]
      imported.push attr
    for key, val of record when key not in imported
      if (attr = @_attributes[key])
        rec[key] = attr.serialize(val)
      else
        @assert @_isDynamic, "unknown attribute `#{ key }` for model `#{ @_name }`"
        rec[key] = record[key]
    rec





module.exports = Class = ModelEx
