utils = require './utils'
CoreObject = require './CoreObject'
RecordStore = require './RecordStore'


Class = null

###*
  Used to manipulate records of a given type. Use {{#crossLink "Database/modelFactory:method"}}{{/crossLink}}
  to get an instance related to a {{#crossLink "Database"}}{{/crossLink}}.

  @since 0.0.2
  @class Model
  @extends CoreObject
  @constructor
###
class Model extends CoreObject
  ###*
    Holds our store, could be a {{#crossLink "MergedRecordStore"}}{{/crossLink}}
    or a simple {{#crossLink "RecordStore"}}{{/crossLink}}
    @since 0.0.2
    @private
    @property _store
    @type RecordStore|MergedRecordStore
  ###
  _store:          null
  ###*
    Name of our model, normalized
    @since 0.0.2
    @private
    @property _name
    @type String
  ###
  _name:           null
  ###*
    Our database object where we came from
    @since 0.0.2
    @private
    @property _database
    @type Database
  ###
  _database:       null
  ###*
    Store our event listener methods that have been self-bound for detaching later
    @since 0.0.2
    @private
    @property _eventListeners
    @type Object
  ###
  _eventListeners: null


  ###*
    Constructs a new instance of `Model`

    @since 0.0.2
    @method constructor
    @param {Database|null} database our database
    @param {String|null} name       our name
    @param {RecordStore} store      our store
  ###
  constructor: (database, name, store) ->
    if name?
      @_name = Class._modelName(name)
    else
      @_name = null
    if database?
      @assert(
          database instanceof Class._databaseClass(),
        "given database isn't an instance of #{ Class._databaseClass().className() }"
      )
      @_database = database
    else
      @_database = null
    if store?
      @assert store instanceof RecordStore, "given store must be an instance of #{ RecordStore.className() }"
      @_store = store
    else
      @_store = new RecordStore()
    @setMaxListeners Infinity
    @_attachEvents()


  ###*
    Creates a new record

    @since 0.0.2
    @method create
    @param {Object} [record={}] the attributes of our record, including a possible `id` if we want to force it
    @return {Object} copy of our new record
  ###
  create: (record) ->
    @_store.createRecord arguments...


  ###*
    Update a record with new given attributes

    @since 0.0.2
    @method update
    @param {String|Number} [id] id of the record to update, if not given, it must be defined in `record.id`
    @param {Object} record      attributes to update
    @return {Object}            copy of the updated record
  ###
  update: (id, record) ->
    @_store.updateRecord arguments...


  ###*
    Deletes a record

    @since 0.0.2
    @method delete
    @param {String|Number} id id of the record to delete
    @return {Object}          copy of the old record which has been deleted
  ###
  delete: (id) ->
    @_store.deleteRecord arguments...


  ###*
    Find a record given its id

    @since 0.0.2
    @method find
    @param {String|Number} id id of the record to get
    @return {Object|undefined} copy of the record, or `undefined` if no such record
  ###
  find: (id) ->
    @_store.readRecord arguments...


  ###*
    Find multiple records at once given their id

    @since 0.0.2
    @method findMany
    @param {Array|Number|String} id* id list of the records to get, or one array with all of them
    @return {Array<Object>} array of all records found
  ###
  findMany: (ids...) ->
    if ids.length is 1 and utils.isArray(ids[0])
      ids = ids[0]
    ids = utils.uniq ids
    record for id in ids when (record = @_store.readRecord id)


  ###*
    Find all records in the store for this model

    @since 0.0.2
    @method findAll
    @return {Array<Object>} array of all records
  ###
  findAll: ->
    @_store.readAllRecords()


  ###*
    Find multiple records using a filter object or function

    @since 0.0.2
    @method findQuery
    @param {Object|Function} filter the object with attributes to match, or a function used to filter records
    @param {Object} [thisArg]       the object to bind `filter` on if it's a function
    @return {Array<Object>}         array of all records which matched
  ###
  findQuery: (filter, thisArg) ->
    utils.filter @_store.readAllRecords(), filter, thisArg


  ###*
    Count all records

    @since 0.0.2
    @method count
    @return {Number} the total count of all records
  ###
  count: ->
    @_store.countRecords()


  ###*
    Destroy this instance, freeing the store

    @since 0.0.2
    @method destroy
  ###
  destroy: ->
    @_detachEvents()
    @_store = null
    @_database = null
    Object.freeze @
    super


  ###*
    Attach events on the store

    @since 0.0.2
    @private
    @method _attachEvents
    @chainable
  ###
  _attachEvents: ->
    unless @_eventListeners
      @_eventListeners = {
        created: @_recordCreated.bind @
        updated: @_recordUpdated.bind @
        deleted: @_recordDeleted.bind @
      }
      for k, v of @_eventListeners
        @_store.on "record.#{k}", v
    @


  ###*
    Detach events if previously attached to the store

    @since 0.0.2
    @private
    @method _detachEvents
    @chainable
  ###
  _detachEvents: ->
    if @_eventListeners
      for k, v of @_eventListeners
        @_store.removeListener "record.#{k}", v
      @_eventListeners = null
    @


  ###*
    Handles the `record.created` event

    @since 0.0.2
    @private
    @method _recordCreated
    @param {Object} record the created record
  ###
  _recordCreated: (record) ->
    @_emit 'created', record


  ###*
    Handles the `record.updated` event

    @since 0.0.2
    @private
    @method _recordUpdated
    @param {Object} record the updated record
  ###
  _recordUpdated: (record) ->
    @_emit "record:#{ if @_name then "#{@_name}" else '-' }##{ record.id }", record
    @_emit 'updated', record


  ###*
    Handles the `record.deleted` event

    @since 0.0.2
    @private
    @method _recordDeleted
    @param {Object} record the deleted record
  ###
  _recordDeleted: (record) ->
    @_emit "record:#{ if @_name then "#{@_name}" else '-' }##{ record.id }", null
    @_emit 'deleted', record


  ###*
    Emits an event from ourself or our database if we have one

    @since 0.0.2
    @private
    @method _emit
    @param {String} event   name of the event
    @param {mixed} [args]*  any additional args to pass to the event handlers
  ###
  _emit: (event, args...) ->
    if @_database
      @_database.emit event, args...
    else
      @emit event, args...


  ###*
    Asserts that the given model name is valid

    @since 0.0.2
    @static
    @method assertValidModelName
    @param {String} name name of the model to check
    @chainable
  ###
  @assertValidModelName: (name) ->
    @assert utils.isString(name) and name.length, "the model name must be a string of at least on char"
    @


  ###*
    Normalize a model name

    @since 0.0.2
    @static
    @private
    @method _modelName
    @param {String} name  name of the model to normalize
    @return {String}      the normalized model name
  ###
  @_modelName: (name) ->
    @assertValidModelName(name)
    utils.camelCase(utils.singularize name)


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


module.exports = Class = Model
