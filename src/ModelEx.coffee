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
    The relationships of this model, indexed by their source accessor
    @since 0.0.7
    @private
    @property _relationships
    @type Object<Relationship>
  ###
  _relationships: null
  ###*
    The relationships of this model, indexed by their source attribute
    @since 0.0.7
    @private
    @property _relationshipsByAttr
    @type Object<Relationship>
  ###
  _relationshipsByAttr: null
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
    Our exported record cache
    @since 0.0.7
    @private
    @property _exportedRecords
    @type Object<Object>
  ###
  _exportedRecords: null


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
    @_relationshipsByAttr = {}
    @_exportedRecords = {}
    @_isDynamic = no
    for own name, type of attributes
      if name is '*'
        @_isDynamic = Boolean(type)
      else
        if type in 'str string num number bool boolean date mixed'.split(' ')
          @_attributes[name] = new ModelAttribute(@, name, type)
        else if type[0] is ':'
          @_relationships[name] = rel = @_parseRelationship(name, type)
          @_relationshipsByAttr[rel.fromAttr()] = rel
        else
          @assert no, "wrong attribute type: #{ type }"
    for own prop, rel of @_relationships
      @assert(
        not @_attributes[rel.fromAttr()],
        "a relationship cannot be defined on an attribute of the model: #{ @_name }.#{ prop }"
      )
    @_store.setImporter @_importRecord.bind(@)
    @_store.setExporter @_exportRecord.bind(@)


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


  # @see {Model.delete}
  delete: (id) ->
    rec = super
    delete @_exportedRecords["#{rec.id}"]
    rec


  # @see {Model.create}
  create: (record) ->
    res = super
    for attr, rel of @_relationshipsByAttr
      if (newVal = res[attr])
        rel._updateRelated res, newVal
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
    Finds the relationship defined on a given accessor name

    @since 0.0.7
    @method relationshipAt
    @param {String} accessor The name of the property where the related record is mapped
    @return {Relationship|undefined} The relationship at this accessor or null if no such relationship defined
  ###
  relationshipAt: (accessor) ->
    @_relationships[accessor]


  destroy: ->
    delete @_exportedRecords[key] for key in Object.keys(@_exportedRecords)
    delete @_relationships[key] for key in Object.keys(@_relationships)
    delete @_relationshipsByAttr[key] for key in Object.keys(@_relationshipsByAttr)
    delete @_attributes[key] for key in Object.keys(@_attributes)
    super


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
      isKnown = yes
      unless (rec = @_exportedRecords["#{record.id}"])
        rec = @_exportedRecords["#{record.id}"] = @_store._copyRecord(record)
        isKnown = no
      defined = ['id']
      for key, attr of @_attributes
        defined.push key
        rec[key] = attr.deserialize(record[key])
      for key, rel of @_relationships
        defined.push (attr = rel.fromAttr())
        if isKnown
          rec[attr] = record[attr]
        else
          rel._setupRecord rec
      # delete undefined or obsolete properties
      unless @_isDynamic
        for key, val of record when key not in defined
          delete rec[key]
      unless isKnown
        # sign our record
        Object.defineProperty(rec, '__modelName', {
          value: @_name
          writable: no
          configurable: no
          enumerable: no
        })
      Object.defineProperty(rec, '__original', {
        value: Object.freeze(record),
        writable: no
        configurable: yes
        enumerable: no
      })
    else
      rec = record
    rec


  ###*
    Import a record, serializing its known attributes and relationships

    @since 0.0.7
    @private
    @method _importRecord
    @param {Object} record The record to import
    @return {Object} The serialized record attributes which have been updated
  ###
  _importRecord: (record) ->
    imported = ['id']
    rec = {}
    rec.id = record.id if record.id
    for key, rel of @_relationships
      attr = rel.fromAttr()
      if hasOwn(record, attr)
        rec[attr] = record[attr]
      else if hasOwn(record, key)
        rec[attr] = rel._serializeRelated record[key]
      imported.push attr
    for key, val of record when key not in imported
      if (attr = @_attributes[key])
        rec[key] = attr.serialize(val)
      else
        @assert @_isDynamic, "unknown attribute `#{ key }` for model `#{ @_name }`"
        rec[key] = record[key]
    # computed differences to only return them and update related records if any
    if rec.id and (originalRecord = @_exportedRecords["#{rec.id}"])
      original = originalRecord.__original
      after = Object.keys(rec)
      diff = {}
      for k in after when k isnt 'id' and original[k] isnt rec[k]
        diff[k] = rec[k]
        if (rel = @_relationshipsByAttr[k])
          rel._updateRelated originalRecord, rec[k], original[k]
      rec = diff
    rec





module.exports = Class = ModelEx
