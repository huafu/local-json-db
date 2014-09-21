utils = require './utils'
CoreObject = require './CoreObject'
DictionaryEx = require './DictionaryEx'

Class = null

class RecordStore extends CoreObject
  _records: null
  _config:  null
  _lastId:  null

  constructor: (records = [], config = {}) ->
    @_records = new DictionaryEx({}, {stringifyKeys: yes})
    @_config = utils.defaults {}, config, {
      createdAtKey: no
      updatedAtKey: no
      deletedAtKey: no
    }
    @_lastId = 0
    @lockProperties '_records', '_config'
    # create a new method instead of using `bind` to be sure we have only the record given as attribute
    utils.map records, (record) => @createRecord(record)

  readRecord: (id) ->
    @assertValidId id
    if (r = @_records.get(id))
      r = @copyRecord r
    r

  createRecord: (record = {}) ->
    @assertValidRecord record
    if (id = record.id)?
      @assertIdExists id, no
      if /^[0-9]$/.test(str = "#{id}") and (int = parseInt(str, 10)) > @_lastId
        @_lastId = int
    else
      id = record.id ?= ++@_lastId
    @_records.set id, @copyRecord(record)
    @emit 'record.created', record
    record

  updateRecord: (id, record) ->
    if arguments.length is 1
      record = id
      id = record.id
    else
      @assert(
        not record.id? or "#{id}" is "#{record.id}",
        "the id given `#{id}` does not match the id in the given record `#{record.id}`"
      )
    @assertValidRecord record
    @assertIdExists id
    rec = @_records.get id
    for own key, value of record when key isnt 'id'
      if value is undefined
        delete rec[key]
      else
        rec[key] = value
    rec = @copyRecord rec
    @emit 'record.updated', rec
    rec

  deleteRecord: (id) ->
    @assertIdExists id
    rec = @_records.unsets(id).value
    @emit 'record.deleted', rec
    rec

  assertValidRecord: (record, mustHaveId = no) ->
    @assert (record and utils.isObject(record)), "not a valid record: #{record}"
    @assertValidId(record.id) if mustHaveId
    @

  assertValidId: (id) ->
    @assert id?, "`#{id}` is not a valid id"

  assertIdExists: (id, exists = yes) ->
    @assertValidId id
    test = @_records.exists id
    if exists
      @assert test, "no record with id `#{id}`"
    else
      @assert (not test), "a record with id `#{id}` already exists"
    @

  copyRecord: (obj) ->
    res = utils.copy obj
    if res?.id?
      utils.lock res, 'id'
    res

  _exportRecord: (record, metadata, keys = @_config) ->
    if record?
      rec = @copyRecord record
      rec[k] = metadata.createdAt if (k = keys.createdAtKey)
      rec[k] = metadata.updatedAt if (k = keys.updatedAtKey)
      rec[k] = metadata.deletedAt if (k = keys.deletedAtKey)
    else
      undefined

  _importRecord: (record, keys = @_config) ->
    m = {
      id: null
      record: @copyRecord record
      metadata: {}
    }
    if record?.id?
      m.id = record.id
    if (k = keys.deletedAtKey) and record[k]
      m.record = null
      m.metadata.deletedAt = record[k]
    else
      if (k = keys.createdAtKey) and record[k]
        m.metadata.createdAt = @_parseDate record[k]
        delete m.record[k]
      if (k = keys.updatedAtKey) and record[k]
        m.metadata.updatedAt = @_parseDate record[k]
        delete m.record[k]
    m







module.exports = Class = RecordStore
