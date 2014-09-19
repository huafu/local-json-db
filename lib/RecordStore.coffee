sysPath = require 'path'
fs = require 'fs'
_ = require 'lodash'
CoreObject = require './CoreObject'
Class = null

copy = (obj, propToLock...) ->
  return obj if obj in [undefined, null]
  res = JSON.parse JSON.stringify(obj)
  CoreObject.__lockProperty(res, prop) for prop in propToLock
  res


class RecordStore extends CoreObject
  @coerceId: (id, throwsIfInvalid = yes) ->
    unless id? and id isnt 0
      if throwsIfInvalid
        @assert no, "invalid id given: #{id}"
      else
        undefined
    "$id$#{id}"


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
    @lockProperties 'path', 'readOnly', 'parent', '_uuid'

  readJSON: ->
    data = JSON.parse fs.readFileSync(@path, encoding: 'utf8')
    @assert _.isArray(data), "the record list file must be a JSON array (#{ @path })"
    data


  writeJSON: (data, prettyPrint = yes) ->
    fs.writeFileSync @path, JSON.stringify(data, null, if prettyPrint then 2 else null), encoding: 'utf8'

  load: (force = no) ->
    if not @_records or force
      @_records = {}
      @_lastId = 0
      @_count = 0
      if fs.existsSync(@path)
        records = @readJSON()
      else
        records = []
      for record in records
        @_registerRecord record
        @_count++
      @emit 'loaded', @_count
    @

  save: ->
    @assertWritable()
    @writeJSON _.values(@_records) if @_records
    @emit 'saved', @_count
    @

  assertWritable: ->
    @assert (not @readOnly), "this record store is read-only (#{ @path })"

  readRecord: (id) ->
    copy @_recordForId(id), 'id'

  deleteRecord: (id, throwIfNoSuchRecord = yes) ->
    @assertWritable()
    dict = @load()._records
    rid = Class.coerceId id
    if (old = dict[rid])
      Object.freeze old
      delete dict[rid]
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
    @emit 'record.created', (res = copy data, 'id')
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
    dict = @load()._records
    @assert dict[rid], "no record found with id: #{ id }"
    old = copy(dict[rid])
    record = dict[rid]
    for own key, value of data when key isnt 'id'
      if value?
        record[key] = value
      else
        delete record[key]
    res = copy(record, 'id')
    @emit 'record.updated', res, old
    res


  _recordForId: (id) ->
    @load()._records[Class.coerceId id]

  _registerRecord: (data) ->
    dict = @_records
    id = Class.coerceId data.id
    @assert (not dict[id]), "a record with id #{ data.id } already exists (#{ @path })"
    if /^[0-9]+$/.test(sid = "#{data.id}") and (intId = parseInt sid, 10) > @_lastId
      @_lastId = intId
    dict[id] = copy(data, 'id')
    @


module.exports = Class = RecordStore
