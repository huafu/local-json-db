utils = require '../utils'
CoreObject = require '../CoreObject'
DictionaryEx = require '../DictionaryEx'
Dictionary = require '../Dictionary'

Class = null

###*
  Holds records and manage a local cache of exported records

  @since 0.0.2
  @class RecordStore
  @extends CoreObject
  @constructor
###
class RecordStore extends CoreObject
  ###*
    Holds our serialized records, which are actually in the store
    @since 0.0.2
    @private
    @property _records
    @type DictionaryEx
  ###
  _records: null
  ###*
    Holds the cache of our exported records
    @since 0.0.7
    @private
    @property _exportCache
    @type Dictionary
  ###
  _exportCache: null
  ###*
    Our configuration
    @since 0.0.2
    @private
    @property _config
    @type Object
  ###
  _config:  null
  ###*
    The last used ID
    @since 0.0.2
    @private
    @property _lastId
    @type Number
    @default 0
  ###
  _lastId:  null
  ###*
    Namespace for our events
    @since 0.0.2
    @private
    @property _eventsNamespace
    @type String
    @default "record"
  ###
  _eventsNamespace: null
  ###*
    The event emitter object
    @since 0.0.2
    @private
    @property _eventsEmitter
    @type EventEmitter
    @default this
  ###
  _eventsEmitter: null
  ###*
    Whether we are read-only or not
    @since 0.0.2
    @private
    @property _readOnly
    @type Boolean
    @default false
  ###
  _readOnly: null


  ###*
    Constructs a new store

    @since 0.0.2
    @method constructor
    @param {Array<Object>} [records] An array of records to import into the store
    @param {Object} [config] Configuration for this store
    @param {String} [config.createdAtKey="createdAt"] The property where to store the creation date of a record
    @param {String} [config.updatedAtKey="updatedAt"] The property where to store the update date of a record
    @param {String} [config.deletedAtKey="deletedAt"] The property where to store the deleted date of a record
    @param {String} [config.eventsNamespace="record"] The namespace for our events
    @param {String} [config.eventEmitter=this] The event emitter object
    @param {String} [config.readOnly=false] Whether we are read-only or not
  ###
  constructor: (records = [], config = {}) ->
    @_records = new DictionaryEx({}, {stringifyKeys: yes})
    @_config = utils.defaults {}, config, {
      createdAtKey: 'createdAt'
      updatedAtKey: 'updatedAt'
      deletedAtKey: 'deletedAt'
      eventsNamespace: 'record'
      eventsEmitter: @
      readOnly: no
    }
    @_exportCache = new Dictionary({}, {stringifyKeys: yes})
    @_readOnly = no
    readOnly = Boolean(@_config.readOnly)
    delete @_config.readOnly
    @_eventsNamespace = @_config.eventsNamespace
    delete @_config.eventsNamespace
    @_eventsEmitter = @_config.eventsEmitter
    delete @_config.eventsEmitter
    @_lastId = 0
    # create a new method instead of using `bind` to be sure we have only the record given as attribute
    @importRecords records
    @_readOnly = readOnly



  _createExportableRecord: (id) ->
    res = {}
    self = @
    Object.defineProperty res, 'id', {value: id, enumerable: yes}
    Object.defineProperty res, '__recordMeta__', value: {original: null}
    Object.defineProperty res, 'save', value: -> self.updateRecord @
    Object.defineProperty res, 'delete', value: -> self.deleteRecord @
    Object.defineProperty res, 'export', value: -> self._barify @
    res


  _exportRecord: (id, entry) ->
    cacheEntry = @_exportCache.entryForKey(id)
    bareRecord = @_entryToRecord(entry)
    if (isNew = cacheEntry.index < 0)
      return undefined unless bareRecord
      record = @_createExportableRecord id
      cacheEntry = @_exportCache.set id, record
    else
      unless bareRecord
        @_exportCache.unset id
        return undefined
      record = cacheEntry.value
    recordMeta = record.__recordMeta__
    recordMeta.original = bareRecord
    checked = ['id']
    for key, value of bareRecord when key isnt 'id'
      record[key] = utils.copy(value)
    unless isNew
      for key, value of record when key not in checked
        delete record[key]
    record


  _recordToEntry: (record) ->
    {
      index: -1
      value: record ? undefined

    }






  _recordDiff: (record, old) ->
    checked = ['id']
    diff = {}
    for key, value of record when key isnt 'id'
      checked.push key
      unless utils.has(old, key) and old[key] is value
        diff[key] = value
    for key, value of old when key not in checked
      # flag as deleted
      diff[key] = null
    diff


  _entryToRecord: (entry) ->
    if entry.index >= 0
      rec = utils.copy entry.value
      rec[k] = entry.metadata.createdAt if (k = @_config.createdAtKey)
      rec[k] = entry.metadata.updatedAt if (k = @_config.updatedAtKey)
    else
      undefined

  _entryForId: (id) ->
    @_records.entryForKey id

  _bareRecord: (id) ->
    @_records.get(id)



  # ===== OLD METHODS ===== #

  readRecord: (id) ->
    @assertValidId id
    @_read id

  readAllRecords: ->
    @_read(id) for id in @ids()

  createRecord: (record = {}) ->
    @assertWritable()
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
    @assertWritable()
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
    @assertWritable()
    @assertIdExists id
    @_delete id, deletedAt

  countRecords: ->
    @_records.count()

  reset: ->
    @assertWritable()
    @_records.clear()
    @

  ids: (includeDeleted = no) ->
    res = @_records.keys()
    if includeDeleted
      res = res.concat @_records.deletedKeys()
    res.sort()

  deletedIds: ->
    @_records.deletedKeys().sort()

  idExists: (id, includeDeleted = no) ->
    @assertValidId id
    exists = @_records.exists(id)
    if not exists and includeDeleted and @_records.deletedExists(id)
      exists = isDeleted: yes
    exists

  importRecords: (records) ->
    @assertWritable()
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

  exportConfig: ->
    res = {}
    for k in ['createdAtKey', 'updatedAtKey', 'deletedAtKey', 'readOnly']
      res[k] = @_config[k] if @_config[k]?
    res

  export: ->
    {
      config: @exportConfig()
      records: @exportRecords()
    }


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

  assertWritable: ->
    @assert (not @_readOnly), "the #{ @className() } is read-only"

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
      if metadata.deletedAt
        rec[k] = metadata.deletedAt if (k = keys.deletedAtKey)
        delete rec[k] if (k = keys.createdAtKey)
        delete rec[k] if (k = keys.updatedAtKey)
      else
        rec[k] = metadata.createdAt if (k = keys.createdAtKey)
        rec[k] = metadata.updatedAt if (k = keys.updatedAtKey)
        delete rec[k] if (k = keys.deletedAtKey)
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
    e = @_records.set meta.id, rec
    e.metadata.createdAt = meta.metadata.createdAt if meta.metadata.createdAt
    e.metadata.updatedAt = meta.metadata.updatedAt if meta.metadata.updatedAt
    rec = @_exportRecord rec, e.metadata
    @_trigger "#{ @_eventsNamespace }.updated", rec
    rec

  _create: (meta) ->
    e = @_records.set meta.id, meta.record
    e.metadata.createdAt = meta.metadata.createdAt if meta.metadata.createdAt
    e.metadata.updatedAt = meta.metadata.updatedAt if meta.metadata.updatedAt
    record = @_exportRecord meta.record, e.metadata
    @_trigger "#{ @_eventsNamespace }.created", record
    record

  _delete: (id, deletedAt = null) ->
    rec = @_records.get id
    e = @_records.unset id
    e.metadata.deletedAt = deletedAt if deletedAt
    rec = @_exportRecord rec, e.metadata
    @_trigger "#{ @_eventsNamespace }.deleted", rec
    rec

  _read: (id, keepDeleted = no) ->
    e = @_records.entryForKey id
    if keepDeleted and not e.value
      rec = {id}
    else
      rec = e.value
    @_exportRecord rec, e.metadata

  _trigger: (event, args...) ->
    @_eventsEmitter?.emit event, args...

  _parseDate: DictionaryEx::_parseDate

  @import: (data) ->
    @assert(
      utils.isObject(data) and utils.isObject(data.config) and utils.isArray(data.records),
      'given data is not valid data to be imported as a RecordStore'
    )
    new @(data.records, data.config)



module.exports = Class = RecordStore
