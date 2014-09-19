sysPath = require 'path'
fs = require 'fs'
_ = require 'lodash'
CoreObject = require './CoreObject'
Class = null

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
    data = require @path
    @assert _.isArray(data), "the record list file must be a JSON array (#{ @path })"
    # wee need a deep clone of the array
    _.cloneDeep(data)


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
    @

  assertWritable: ->
    @assert (not @readOnly), "this record store is read-only (#{ @path })"

  find: (id) ->
    @_recordForId id

  deleteRecord: (id, throwIfNoSuchRecord = yes) ->
    @assertWritable()
    dict = @load()._records
    rid = Class.coerceId id
    if dict[rid]
      Object.freeze dict[rid]
      delete dict[rid]
      @_count--
    else
      @assert (not throwIfNoSuchRecord), "trying to delete a unknown record with id #{ id }"
    # be sure to not return anything
    return

  createRecord: (data = {}) ->
    @assertWritable()
    @load() # to be sure to have the _lastId property correctly set
    data.id ?= ++this._lastId
    res = @_registerRecord data
    @_count++
    res

  count: ->
    @load()._count


  _recordForId: (id) ->
    @load()._records[Class.coerceId id]

  _registerRecord: (data) ->
    dict = @_records
    id = Class.coerceId data.id
    @assert (not dict[id]), "a record with id #{ data.id } already exists (#{ @path })"
    if /^[0-9]+$/.test(sid = "#{data.id}") and (intId = parseInt sid, 10) > @_lastId
      @_lastId = intId
    dict[id] = data
    CoreObject.__lockProperty dict[id], 'id'
    Object.freeze(dict[id]) if @readOnly
    dict[id]


module.exports = Class = RecordStore
