utils = require './utils'
CoreObject = require './CoreObject'
DictionaryEx = require './DictionaryEx'

Class = null

class RecordStore extends CoreObject
  _records: null
  _config:  null
  _lastId:  null
  _eventsNamespace: null

  constructor: (records = [], config = {}) ->
    @_records = new DictionaryEx({}, {stringifyKeys: yes})
    @_config = utils.defaults {}, config, {
      createdAtKey: 'createdAt'
      updatedAtKey: 'updatedAt'
      deletedAtKey: 'deletedAt'
      eventsNamespace: 'record'
    }
    @_eventsNamespace = @_config.eventsNamespace
    delete @_config.eventsNamespace
    @_lastId = 0
    @lockProperties '_records', '_config', '_eventsNamespace'
    # create a new method instead of using `bind` to be sure we have only the record given as attribute
    @importRecords records

  readRecord: (id) ->
    @assertValidId id
    @_read id

  createRecord: (record = {}) ->
    @assertValidRecord record
    m = @_importRecord record
    @assert m.record, "trying to create a record flagged as deleted"
    if (id = m.id)?
      @assertIdExists id, no
      if /^[0-9]+$/.test(str = "#{id}") and (int = parseInt(str, 10)) > @_lastId
        @_lastId = int
    else
      m.id = m.record.id = ++@_lastId
    @_create m

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
    @_update m

  deleteRecord: (id, deletedAt = null) ->
    @assertIdExists id
    @_delete id, deletedAt

  countRecords: ->
    @_records.count()

  reset: ->
    @_records.clear()
    @

  ids: (includeDeleted = no) ->
    res = @_records.keys()
    if includeDeleted
      res = res.concat @_records.deletedKeys()
    res

  deletedIds: ->
    @_records.deletedKeys()

  idExists: (id, includeDeleted = no) ->
    @assertValidId id
    exists = @_records.exists(id)
    if not exists and includeDeleted and @_records.deletedExists(id)
      exists = isDeleted: yes
    exists

  importRecords: (records) ->
    for record in records
      m = @_importRecord record
      @assertIdExists m.id, no
      if /^[0-9]+$/.test(sid = "#{m.id}") and (int = parseInt sid, 10) > @_lastId
        @_lastId = int
      if m.record
        e = @_records.set m.id, m.record
        e.metadata.createdAt = m.metadata.createdAt if m.metadata.createdAt
        e.metadata.updatedAt = m.metadata.updatedAt if m.metadata.updatedAt
      else
        @assert (not @_records.deletedExists m.id), "record with id #{m.id} already flagged as deleted"
        @_records.deleted(m.id, m.metadata.deletedAt ? null)
    @

  exportRecords: ->
    @_read(id, yes) for id in @ids(@_config.deletedAtKey)


  assertValidRecord: (record, mustHaveId = no) ->
    @assert (record and utils.isObject(record)), "not a valid record: #{record}"
    @assertValidId(record.id) if mustHaveId
    @

  assertValidId: (id) ->
    @assert id?, "`#{id}` is not a valid id"

  assertIdExists: (id, exists = yes) ->
    test = @idExists id
    if exists
      @assert test, "no record with id `#{id}`"
    else
      @assert (not test), "a record with id `#{id}` already exists"
    @

  lastAutoId: ->
    @_lastId

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
      rec
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

  _update: (meta) ->
    rec = (e = @_records.entryForKey meta.id).value
    for own key, value of meta.record when key isnt 'id'
      if value is undefined
        delete rec[key]
      else
        rec[key] = value
    e.metadata.createdAt = meta.metadata.createdAt if meta.metadata.createdAt
    e.metadata.updatedAt = meta.metadata.updatedAt if meta.metadata.updatedAt
    rec = @_exportRecord rec, e.metadata
    @emit "#{ @_eventsNamespace }.updated", rec
    rec

  _create: (meta) ->
    e = @_records.set meta.id, meta.record
    e.metadata.createdAt = meta.metadata.createdAt if meta.metadata.createdAt
    e.metadata.updatedAt = meta.metadata.updatedAt if meta.metadata.updatedAt
    record = @_exportRecord meta.record, e.metadata
    @emit "#{ @_eventsNamespace }.created", record
    record

  _delete: (id, deletedAt = null) ->
    rec = @_records.get id
    e = @_records.unset id
    e.metadata.deletedAt = deletedAt if deletedAt
    rec = @_exportRecord rec, e.metadata
    @emit "#{ @_eventsNamespace }.deleted", rec
    rec

  _read: (id, keepDeleted = no) ->
    e = @_records.entryForKey id
    if keepDeleted and not e.value
      rec = {id}
    else
      rec = e.value
    @_exportRecord rec, e.metadata

  _parseDate: DictionaryEx::_parseDate



module.exports = Class = RecordStore
