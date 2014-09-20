sysPath = require 'path'
fs = require 'fs'
utils = require './utils'
CoreObject = require './CoreObject'


Class = null

copy = (obj, propToLock...) ->
  res = utils.copy obj
  unless res in [null, undefined]
    utils.lock(res, prop) for prop in propToLock
  res


class RecordStore extends CoreObject
  @coerceId: (id, throwsIfInvalid = yes) ->
    unless id? and id isnt 0
      if throwsIfInvalid
        @assert no, "invalid id given: #{id}"
      else
        undefined
    "$id$#{id}"
  @copy: copy


  _records: null
  _lastId: null
  readOnly: null
  path: null

  constructor: (path, options = {}) ->
    @path = sysPath.resolve path
    @readOnly = Boolean(options.readOnly)
    @_records = null
    @_uuid = @path
    @_count = null
    @_lastId = null
    @_config = null
    @lockProperties 'path', 'readOnly', 'parent', '_uuid'

  readJSON: ->
    data = JSON.parse fs.readFileSync(@path, encoding: 'utf8')
    @assert utils.isArray(data.records), "the records resource file must contains a `records` array (#{ @path })"
    data


  writeJSON: (data, prettyPrint = yes) ->
    fs.writeFileSync @path, JSON.stringify(data, null, if prettyPrint then 2 else null), encoding: 'utf8'

  load: (force = no) ->
    if not @_records or force
      @_records = {}
      @_config = null
      @_lastId = 0
      @_count = 0
      if fs.existsSync(@path)
        {records, config} = @readJSON()
        @_config = config
      else
        records = []
      @_config ?= {}
      for record in records
        @_registerRecord record
        @_count++
      @emit 'loaded', @_count
    @

  save: ->
    @assertWritable()
    @writeJSON {config: @_config, records: utils.values(@_records)} if @_records
    @emit 'saved', @_count
    @

  isLoaded: ->
    Boolean(@_records)

  assertWritable: ->
    @assert (not @readOnly), "this record store is read-only (#{ @path })"

  readRecord: (id) ->
    Class.copy @load()._readRecord(Class.coerceId id), 'id'

  deleteRecord: (id, throwIfNoSuchRecord = yes) ->
    @assertWritable()
    @load()
    rid = Class.coerceId id
    if (old = @_readRecord rid)
      @_deleteRecord rid
      @_count--
      @emit 'record.deleted', old
    else
      @assert (not throwIfNoSuchRecord), "trying to delete a unknown record with id #{ id }"
    # be sure to not return anything
    return

  createRecord: (data = {}) ->
    @assertWritable()
    @load() # to be sure to have the _lastId property correctly set
    data.id ?= ++this._lastId
    @_registerRecord data
    @_count++
    @emit 'record.created', (res = Class.copy data, 'id')
    res

  countRecords: ->
    @load()._count


  updateRecord: (id, data) ->
    @assertWritable()
    if arguments.length is 1
      data = id
      id = data.id
    rid = Class.coerceId(id)
    @assert(
      data.id is undefined or rid is Class.coerceId(data.id),
      "the given id and the one in the data to be updated are different"
    )
    @load()
    @assert (record = @_readRecord rid), "no record found with id: #{ id }"
    old = Class.copy record, 'id'
    @_writeRecord rid, id, data
    res = Class.copy(record, 'id')
    @emit 'record.updated', res, old
    res

  _registerRecord: (data) ->
    @load()
    id = data.id
    rid = Class.coerceId id
    @assert (not @_readRecord rid), "a record with id #{ id } already exists (#{ @path })"
    if /^[0-9]+$/.test(sid = "#{id}") and (intId = parseInt sid, 10) > @_lastId
      @_lastId = intId
    @_writeRecord rid, id, data, yes
    @

  _readRecord: (rid) ->
    @_records[rid]

  _writeRecord: (rid, id, data = {}, override = no) ->
    if id is null
      id = @_records[rid].id
    if override or not (rec = @_records[rid])
      @_records[rid] = rec = {id}
      utils.lock rec, 'id'
    for own key, val of data when key isnt 'id'
      if val isnt undefined
        rec[key] = val
      else
        delete rec[key]
    rec

  _deleteRecord: (rid) ->
    delete @_records[rid]


module.exports = Class = RecordStore
