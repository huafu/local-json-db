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
    @importRecords records

  readRecord: (id) ->
    @assertValidId id
    e = @_records.entryForKey(id)
    @_exportRecord e.value, e.metadata

  createRecord: (record = {}) ->
    @assertValidRecord record
    m = @_importRecord record
    @assert m.record, "trying to create a record flagged as deleted"
    if (id = m.id)?
      @assertIdExists id, no
      if /^[0-9]$/.test(str = "#{id}") and (int = parseInt(str, 10)) > @_lastId
        @_lastId = int
    else
      id = m.record.id ?= ++@_lastId
    e = @_records.set id, m.record
    e.metadata.createdAt = m.metadata.createdAt if m.metadata.createdAt
    e.metadata.updatedAt = m.metadata.updatedAt if m.metadata.updatedAt
    @emit 'record.created', record
    record

  updateRecord: (id, record) ->
    if arguments.length is 1
      record = id
    else
      @assert(
        not record.id? or "#{id}" is "#{record.id}",
        "the id given `#{id}` does not match the id in the given record `#{record.id}`"
      )
      record.id = id
    @assertValidRecord record
    m = @_importRecord record
    @assert m.record, "trying to update a record flagged as deleted"
    @assertIdExists m.id
    rec = (e = @_records.entryForKey m.id).value
    for own key, value of m.record when key isnt 'id'
      if value is undefined
        delete rec[key]
      else
        rec[key] = value
    e.metadata.createdAt = m.metadata.createdAt if m.metadata.createdAt
    e.metadata.updatedAt = m.metadata.updatedAt if m.metadata.updatedAt
    rec = @_exportRecord rec, e.metadata
    @emit 'record.updated', rec
    rec

  deleteRecord: (id, deletedAt = null) ->
    @assertIdExists id
    rec = @_records.get(id)
    e = @_records.unset id
    e.metadata.deletedAt = deletedAt if deletedAt
    rec = @_exportRecord rec, e.metadata
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

  _copyRecord: (obj) ->
    res = utils.copy obj
    if res?.id?
      utils.lock res, 'id'
    res

  _exportRecord: (record, metadata, keys = @_config) ->
    if record?
      rec = @_copyRecord record
      rec[k] = metadata.createdAt if (k = keys.createdAtKey)
      rec[k] = metadata.updatedAt if (k = keys.updatedAtKey)
      rec[k] = metadata.deletedAt if (k = keys.deletedAtKey)
    else
      undefined

  _importRecord: (record, keys = @_config) ->
    m = {
      id: null
      record: @_copyRecord record
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
