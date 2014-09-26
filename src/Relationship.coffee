utils = require './utils'
CoreObject = require './CoreObject'

Class = null

hasOwn = (o, p) -> {}.hasOwnProperty.call o, p

###*
  Holds a relationship between 2 models

  @since 0.0.7
  @class RelationShip
  @extends CoreObject
  @constructor
###
class Relationship extends CoreObject
  ###*
    Our database
    @since 0.0.7
    @private
    @property _database
    @type Database
  ###
  _database:        null
  ###*
    The source of the relation, including `model`, `attribute` and `accessor`
    @since 0.0.7
    @private
    @property _from
    @type Object
  ###
  _from:            null
  ###*
    The destination of the relation, including `model` and `attribute`
    @since 0.0.7
    @private
    @property _to
    @type Object
  ###
  _to:              null
  ###*
    The inverse relationship if any
    @since 0.0.7
    @private
    @property _inverse
    @type Relationship
  ###
  _inverse: null
  ###*
    Whether the relation is a `has many` relation kind
    @since 0.0.7
    @private
    @property _hasMany
    @type Boolean
  ###
  _hasMany:         null


  ###*
    Constructs a new relationship between 2 models in a database

    @since 0.0.7
    @method constructor
    @param {Database} database The database holding the relation and its models
    @param {Object} from The relation source description
    @param {String} from.model Name of the source model
    @param {String} [from.attribute] Name of the source attribute (holding the id or list of ids)
    @param {String} [from.accessor] Name of the accessor on a record to map the related model(s) to
    @param {Object} to The relation destination description
    @param {String} to.model Name of the destination model
    @param {String} [to.accessor] Name of the accessor on a linked record where the source model(s) is/are mapped
    @param {Boolean} [hasMany=false] Whether the relation is a `has many` relation kind
  ###
  constructor:      (database, from, to, hasMany) ->
    @assert(
      database and database instanceof Class._databaseClass(),
      "you must give a Database object as first parameter"
    )
    @_database = database
    @_from =
      model: null
      modelName: Class._databaseClass()._modelName(from.model)
      attribute: from.attribute
      accessor: from.accessor
    @_to =
      model: null
      modelName: Class._databaseClass()._modelName(to.model)
      attribute: 'id'
      accessor: to.accessor
    @_hasMany = Boolean(hasMany)
    @_inverse = undefined


  ###*
    Returns the source Model instance

    @since 0.0.7
    @method fromModel
    @return {Model} The source model
  ###
  fromModel: ->
    unless (model = @_from.model)
      @_from.model = model = @_database.modelFactory(@_from.modelName)
    model


  ###*
    Returns the destination Model instance

    @since 0.0.7
    @method toModel
    @return {Model} The destination model
  ###
  toModel: ->
    unless (model = @_to.model)
      @_to.model = model = @_database.modelFactory(@_to.modelName)
    model


  ###*
    Returns the source attribute name

    @since 0.0.7
    @method fromAttr
    @return {String} The source attribute name
  ###
  fromAttr: ->
    unless (attr = @_from.attribute)
      @_from.attribute = attr = Class._databaseClass()._attributeForRelationship(@_to.modelName, @_hasMany)
    attr


  ###*
    Returns the destination attribute name

    @since 0.0.7
    @method toAttr
    @return {String} The destination attribute
  ###
  toAttr: ->
    unless (attr = @_to.attribute)
      @_to.attribute = attr = 'id'
    attr


  ###*
    Returns the source accessor name

    @since 0.0.7
    @method fromAccessor
    @return {String} The source accessor
  ###
  fromAccessor: ->
    unless (key = @_from.accessor)
      @_from.accessor = key = Class._databaseClass()._accessorForRelationship(@_to.modelName, @_hasMany)
    key


  ###*
    Returns the destination accessor name

    @since 0.0.7
    @method toAccessor
    @return {String} The source accessor
  ###
  toAccessor: ->
    unless (key = @_to.accessor)
      @_to.accessor = key = Class._databaseClass()._accessorForRelationship(@_from.modelName, not @_hasMany)
    key


  ###*
    Returns the inverse relationship, ie the relationship going from our destination to our source models

    @since 0.0.7
    @method inverseRelationship
    @return {Relationship} The inverse relationship
  ###
  inverseRelation: ->
    if (rel = @_inverse) is undefined
      if (rel = @toModel().relationshipAt @toAccessor()) and
          rel.toModel() is @fromModel() and
          rel.hasMany() is not @hasMany()
        @_inverse = rel
      else
        @_inverse = rel = null
    rel


  ###*
    Returns whether this relationship is a `has many` relationship or not

    @since 0.0.7
    @method hasMany
    @return {Boolean} Returns `true` if it's a `has many` relationship, else `false`
  ###
  hasMany: ->
    @_hasMany


  ###*
    Deserialize an attribute value into the linked records as described by this relation

    @since 0.0.7
    @private
    @method _deserializeRelated
    @param {Array<String|Number>|String|Number|undefined} attrValue The value of the from attribute used to find related record(s)
    @return {Array<Object>|Object|undefined} The array of records if it's a `hsMany` relationship, else the record or undefined
  ###
  _deserializeRelated: (attrValue) ->
    if @_hasMany
      if attrValue and attrValue.length
        @_database.findMany @_to.modelName, attrValue
      else
        []
    else
      if attrValue
        @_database.find @_to.modelName, attrValue
      else
        undefined


  ###*
    Serialize an array of related record or one record into the from attribute value as described by the relation

    @since 0.0.7
    @private
    @method _serializedRelated
    @param {Array<Object>|Object|undefined} related The related record(s) to serialize
    @return {Array<String|Number>|String|Number|undefined} The serialized value as in our source attribute value
  ###
  _serializeRelated: (related) ->
    if @_hasMany
      if related and related.length
        utils.map related, @toAttr()
      else
        []
    else
      if related
        related[@toAttr()]
      else
        undefined


  ###*
    Setup a record so that the accessor will be a getter/setter for our relation

    @since 0.0.7
    @private
    @method _setupRecord
    @param {Object} record The record to setup
    @chainable
  ###
  _setupRecord: (record) ->
    self = @
    key = @fromAccessor()
    attr = @fromAttr()
    # prepare our cache
    unless record.__rlCache
      Object.defineProperty record, '__rlCache', value: {}, writable: no, enumerable: no, configurable: yes
    record.__rlCache[attr] = record[attr]
    delete record[attr]
    delete record[key]
    # setup the magic hidden property
    Object.defineProperty(
      record,
      key,
      get: ->
        unless hasOwn @__rlCache, key
          @__rlCache[key] = self._deserializeRelated @[attr]
        @__rlCache[key]
      set: (value) ->
        delete @__rlCache[attr]
        @__rlCache[key] = value
      configurable: yes
      enumerable: no
    )
    # define our attribute
    Object.defineProperty(
      record,
      attr,
      get: ->
        if hasOwn(@__rlCache, key)
          self._serializeRelated @__rlCache[key]
        else
          @__rlCache[attr]
      set: (value) ->
        delete @__rlCache[key]
        @__rlCache[attr] = value
      configurable: yes
      enumerable: yes
    )
    @


  ###*
    Return the {{#crossLink "Database"}}{{/crossLink}} class, used to avoid cross-referencing packages

    @since 0.0.2
    @static
    @private
    @method _databaseClass
    @return {Object} the `Database` class
  ###
  @_databaseClass: ->
    require './Database'








module.exports = Class = Relationship
