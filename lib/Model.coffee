utils = require './utils'
CoreObject = require './CoreObject'
RecordStore = require './RecordStore'
Database = require './Database'


Class = null


class Model extends CoreObject
  _store: null
  _name: null
  _database: null
  _eventListeners: null

  constructor: (database, name, store) ->
    if name?
      @_name = Database._modelName(name)
    else
      @_name = null
    if database?
      @assert database instanceof Database, "given database isn't an instance of #{ Database.className() }"
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

  create: (record) ->
    @_store.createRecord arguments...

  update: (id, record) ->
    @_store.updateRecord arguments...

  delete: (id) ->
    @_store.deleteRecord arguments...

  find: (id) ->
    @_store.readRecord arguments...

  findMany: (ids...) ->
    if ids.length is 1 and utils.isArray(ids[0])
      ids = ids[0]
    ids = utils.uniq ids
    record for id in ids when (record = @_store.readRecord id)

  findAll: ->
    @_store.readAllRecords()

  findQuery: (filter, thisArg) ->
    utils.filter @_store.readAllRecords(), filter, thisArg

  count: ->
    @_store.countRecords()

  destroy: ->
    @_detachEvents()
    @_store = null
    @_database = null
    Object.freeze @
    super

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

  _detachEvents: ->
    if @_eventListeners
      for k, v of @_eventListeners
        @_store.removeListener "record.#{k}", v
      @_eventListeners = null
    @

  _recordCreated: (record) ->
    @_emit 'created', record

  _recordUpdated: (record) ->
    @_emit "record:#{ if @_name then "#{@_name}" else '-' }##{ record.id }", record
    @_emit 'updated', record

  _recordDeleted: (record) ->
    @_emit "record:#{ if @_name then "#{@_name}" else '-' }##{ record.id }", null
    @_emit 'deleted', record

  _emit: (event, args...) ->
    if @_database
      @_database.emit event, args...
    else
      @emit event, args...



module.exports = Class = Model
