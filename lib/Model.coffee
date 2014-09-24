utils = require './utils'
CoreObject = require './CoreObject'
RecordStore = require './RecordStore'
Database = require './Database'


Class = null


class Model extends CoreObject
  _store: null
  name: null
  database: null

  constructor: (database, name, store) ->
    if name?
      @name = Database._modelName(name)
    else
      @name = null
    if database?
      @assert database instanceof Database, "given database isn't an instance of #{ Database.className() }"
      @database = database
    else
      @database = null
    if store?
      @assert store instanceof RecordStore, "given store must be an instance of #{ RecordStore.className() }"
      @_store = store
    else
      @_store = new RecordStore()
    @lockProperties 'name', 'database', '_store'

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



module.exports = Class = Model
