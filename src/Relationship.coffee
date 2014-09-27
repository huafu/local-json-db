utils = require './utils'
CoreObject = require './CoreObject'
Model = require './Model'

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
    @param {String} [to.attribute] Name of the destination attribute
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
      modelName: Model._modelName(from.model)
      attribute: from.attribute
      accessor: from.accessor
    @_to =
      model: null
      modelName: Model._modelName(to.model)
      attribute: to.attribute
      accessor: to.accessor
    @_hasMany = Boolean(hasMany)
    @_inverse = undefined
    #@assert(
    #  @_from.attribute isnt 'id',
    #  "the source attribute of the relationship between #{ @_from.modelName } and #{ @_to.modelName } cannot be `id`"
    #)


  ###*
    Finds whether this relation is volatile on its source record

    @since 0.0.7
    @method isVolatile
    @return {Boolean} Returns `true` if the relation is volatile, else `false`
  ###
  isVolatile: ->
    if (res = @_from.volatile) is undefined
      if @_hasMany
        res = Boolean(@inverseRelationship())
      else
        res = @fromAttr() is 'id'
      @_from.volatile = res
    res


  ###*
    Whether we can write to the attribute of this relation or not

    @since 0.0.7
    @method isWritable
    @return {Boolean} Returns `true` if the relation is writable locally, else `false`
  ###
  isWritable: ->
    if (res = @_from.writable) is undefined
      if @toAttr() is 'id'
        if @_hasMany
          res = not @inverseRelationship()
        else
          res = @fromAttr() isnt 'id'
      else
        res = no
      @_from.writable = res
    res


  ###*
    Asserts that the relation is writable on source records, else throw an error

    @since 0.0.7
    @method assertWritable
    @chainable
  ###
  assertWritable: ->
    @assert(
      @isWritable(),
      "the left side of #{@identify()} is read-only"
    )
    @


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
    @return {String} The source accessor name
  ###
  fromAccessor: ->
    unless (key = @_from.accessor)
      @_from.accessor = key = Class._databaseClass()._accessorForRelationship(@_to.modelName, @_hasMany)
    key


  ###*
    Returns the destination accessor name

    @since 0.0.7
    @method toAccessor
    @return {String|null} The destination accessor name or null if no inverse relation
  ###
  toAccessor: ->
    @_to.accessor


  ###*
    Returns the inverse relationship, ie the relationship going from our destination to our source models

    @since 0.0.7
    @method inverseRelationship
    @return {Relationship} The inverse relationship
  ###
  inverseRelationship: ->
    if (rel = @_inverse) is undefined
      if (ta = @toAccessor()) and (rel = @toModel().relationshipAt ta)
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


  # @see {CoreObject#identify}
  uuid: ->
    "#{@_from.modelName}.#{@fromAttr()}-#{@_to.modelName}.#{@toAttr()}"


  ###*
    Deserialize an attribute value into the linked records as described by this relation

    @since 0.0.7
    @private
    @method _deserializeRelated
    @param {Array<String|Number>|String|Number|undefined} attrValue The value of the from attribute used to find related record(s)
    @return {Array<Object>|Object|undefined} The array of records if it's a `hsMany` relationship, else the record or undefined
  ###
  _deserializeRelated: (attrValue) ->
    @assert(
      @toAttr() is 'id',
      "unable to deserialize the given related value for this relationship, its destination attribute isn't `id` (#{@identify()})"
    )
    if @_hasMany
      if attrValue and attrValue.length
        @toModel().findMany attrValue, yes
      else
        []
    else
      if attrValue
        @toModel().find attrValue
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
      Object.defineProperty record, '__rlCache', value: {}, writable: no, enumerable: no, configurable: no
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
        self.assertWritable()
        oldVal = @[key]
        return value unless Class._compareAccessorValues(oldVal, value, self._hasMany)
        delete @__rlCache[attr]
        @__rlCache[key] = value
      configurable: no
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
        #self.assertWritable()
        oldAttr = @[attr]
        return value unless Class._compareAttrValues(oldAttr, value, self._hasMany)
        delete @__rlCache[key]
        @__rlCache[attr] = value
      configurable: no
      enumerable: not @isVolatile()
    )
    @


  ###*
    Update the related record(s) depending on our relation, following the changes made by old => new
    TODO: split this in 2 or 3 sub-methods, it's too heavy

    @since 0.0.7
    @private
    @method _updateRelated
    @param {Object} fromRecord Our source record with our relation's attribute update
    @param {mixed} newAttrValue The new value for our attribute in `fromRecord`
    @param {mixed} oldAttrValue The old value for our attribute in `fromRecord`
    @chainable
  ###
  _updateRelated: (fromRecord, newAttrValue, oldAttrValue) ->
    if (inverse = @inverseRelationship()) and (invAttr = inverse.fromAttr()) isnt 'id'
      invKey = inverse.fromAccessor()
      toModel = @toModel()

      if inverse.isVolatile()
        if @_hasMany
          oldIds = utils.uniq ("#{id}" for id in (oldAttrValue ? []))
          newIds = utils.uniq ("#{id}" for id in (newAttrValue ? []))
          for id in oldIds when id not in newIds and (r = toModel._exportedRecords[id])
            delete r.__rlCache[invKey]
            r.__rlCache[invAttr] = null
          v = fromRecord[inverse.toAttr()]
          for id in newIds when id not in oldIds and (r = toModel._exportedRecords[id])
            delete r.__rlCache[invKey]
            r.__rlCache[invAttr] = v
        else
          unless inverse._hasMany
            if oldAttrValue and (r = toModel._exportedRecords["#{oldAttrValue}"])
              delete r.__rlCache[invKey]
              r.__rlCache[invAttr] = null
            if newAttrValue
              delete r.__rlCache[invKey]
              r.__rlCache[invAttr] = fromRecord[inverse.toAttr()]

      else if @_hasMany
        # update the related records' `inverse.fromAttr()` using our `inverse.toAttr()`
        # we need to:
        #   - set to `undefined` the `inverse.fromAttr()` in each record which is in oldAttrValue and not in newAttrValue
        #   - set to `fromRecord[inverse.toAttr()]` the `inverse.fromAttr()` of each record which is in newAttrValue and not in oldAttrValue
        oldIds = utils.uniq ("#{id}" for id in (oldAttrValue ? []))
        newIds = utils.uniq ("#{id}" for id in (newAttrValue ? []))
        upd = {}
        upd[invAttr] = null
        for id in oldIds when id not in newIds
          toModel.update id, upd
        upd = {}
        upd[invAttr] = fromRecord[inverse.toAttr()]
        for id in newIds when id not in oldIds
          toModel.update id, upd

      else
        if @fromAttr() is 'id'
          # we are not writable, check if we have an inverse which is not `hasMany` and is not on `id` too
          unless inverse._hasMany
            # update our related (2 updates if old and new are not null and different)
            # 1. unset in the old record
            if oldAttrValue
              upd = {}
              upd[invAttr] = null
              toModel.update oldAttrValue, upd
            # 2. set in the new record
            if newAttrValue
              upd = {}
              upd[invAttr] = fromRecord[inverse.toAttr()]
              toModel.update newAttrValue, upd
    @


  ###*
    Compare 2 accessor values of a relation

    @since 0.0.7
    @private
    @static
    @method _compareAccessorValues
    @param {mixed} one The first value to compare
    @param {mixed} two The second value to compare
    @param {Boolean} hasMany Whether the relation is a `has many` or not
    @return {Number} Returns 0 if same, else non-zero
  ###
  @_compareAccessorValues: (one, two, hasMany) ->
    if hasMany
      a = one ? []
      b = two ? []
      return -1 if a.length isnt b.length
      for r, i in a when r isnt b[i]
        return -1
      return 0
    else
      if one? and two?
        return if one is two then 0 else -1
      else if not one? and not two?
        return 0
      else
        return -1


  ###*
    Compare 2 attributes of a relation

    @since 0.0.7
    @private
    @static
    @method _compareAttrValues
    @param {mixed} one The first value to compare
    @param {mixed} two The second value to compare
    @param {Boolean} hasMany Whether the relation is a `has many` or not
    @return {Number} Returns 0 if same, else non-zero
  ###
  @_compareAttrValues: (one, two, hasMany) ->
    if hasMany
      a = one ? []
      b = two ? []
      return -1 if a.length isnt b.length
      for id, i in a when "#{id}" isnt "#{b[i]}"
        return -1
      return 0
    else
      if one? and two?
        return if "#{one}" is "#{two}" then 0 else -1
      else if not one? and not two?
        return 0
      else
        return -1



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
