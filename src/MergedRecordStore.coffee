utils = require './utils'
CoreObject = require './CoreObject'
RecordStore = require './RecordStore'

Class = null


###*
  Handle a merged record store with one or more layers of stores

  @since 0.0.2
  @class MergedRecordStore
  @extends RecordStore
  @constructor
###
class MergedRecordStore extends RecordStore
  ###*
    All our stores, from the bottom one to the top one (the top one being the writable one)
    @since 0.0.2
    @private
    @property _layers
    @type Array<RecordStore>
  ###
  _layers: null
  ###*
    Namespace for each store event, events will then be like `layer0.{namespace}.updated`
    @since 0.0.2
    @private
    @property _eventsNamespace
    @type String
    @default "record"
  ###
  _eventsNamespace: null
  ###*
    Namespace for our record events, outside of each layer, events will then be like `{namespace}.updated`
    @since 0.0.2
    @private
    @property _globalEventsNamespace
    @type String
    @default "record"
  ###
  _globalEventsNamespace: null
  ###*
    Used as a record importer
    @since 0.0.7
    @private
    @property _importer
    @type Function
  ###
  _importer: null
  ###*
    Used as a record exporter
    @since 0.0.7
    @private
    @property _exporter
    @type Function
  ###
  _exporter: null


  ###*
    Constructs an extended record store

    @since 0.0.2
    @method constructor
    @param {Array<Object>} [records=[]] The records to import in the base layer
    @param {Object} [config={}] The configuration of the base layer and default config for all layers
    @param {String|Boolean} [config.createdAtKey=false] The key where to store the creation date
    @param {String|Boolean} [config.updatedAtKey=false] The key where to store the update date
    @param {String|Boolean} [config.deletedAtKey="__deleted"] The key where to store the deletion date
    @param {String} [config.eventsNamespace="record"] The namespace for our events
  ###
  constructor: (records = [], config = {}) ->
    @_config = utils.defaults {}, config, {
      createdAtKey: no
      updatedAtKey: no
      eventsNamespace: 'record'
    }
    @_importer = (r) -> r
    @_exporter = (r) -> r
    @_config.deletedAtKey = '__deleted' unless @_config.deletedAtKey
    @_globalEventsNamespace = @_config.eventsNamespace
    @_eventsEmitter = @
    delete @_config.eventsNamespace
    @_layers = []
    @_lastId = 0
    @addLayer records, {}
    coreLayer = @_layers[0]
    @_records = coreLayer._records
    @_eventsNamespace = coreLayer._eventsNamespace
    @_readOnly = coreLayer._readOnly
    @lockProperties(
      '_layers', '_eventsNamespace', '_records', '_config', '_globalEventsNamespace', '_readOnly'
    )


  ###*
    Defines the importer to be used

    @since 0.0.7
    @method setImporter
    @param {Function|null} importer The importer to use
    @chainable
  ###
  setImporter: (importer = (r) -> r) ->
    @assert utils.isFunction(importer), "the importer must be a function"
    @_importer = importer
    @


  ###*
    Defines the exporter to be used

    @since 0.0.7
    @method setExporter
    @param {Function|null} exporter The exporter to use
    @chainable
  ###
  setExporter: (exporter = (r) -> r) ->
    @assert utils.isFunction(exporter), "the exporter must be a function"
    @_exporter = exporter
    @


  addLayer: (records = [], config = {}) ->
    # be sure the other layers follow our config
    conf = utils.defaults {}, @_config, config, {
      eventsNamespace: "layer#{ @_layers.length }.#{ config.eventsNamespace ? @_globalEventsNamespace }"
      eventsEmitter: @
    }
    if @_layers.length
      conf.readOnly = yes
    @_layers.push (rs = new RecordStore(records, conf))
    @_lastId = Math.max @_lastId, rs.lastAutoId()
    rs

  removeLayer: (index) ->
    @assert (utils.isNumber(index) and @_layers[index]?), "invalid layer index: #{ index }"
    @assert index isnt 0, "the base layer (with index 0) can't be removed"
    @_layers.splice(index, 1).pop()

  layers: (index) ->
    if arguments.length > 0
      @assert (utils.isNumber(index) and @_layers[index]?), "invalid layer index: #{ index }"
      @_layers[index]
    else
      @_layers.slice()

  idExists: (id, includeDeleted = no) ->
    @assertValidId id
    res = no
    for layer in @_layers when (has = layer.idExists id, yes)
      if has.isDeleted
        res = Boolean(includeDeleted)
        break
      else
        res = yes
    res

  createRecord: (record = {}) ->
    record = @_exporter super(@_importer record)
    @emit "#{ @_globalEventsNamespace }.created", record
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
    record = @_exporter super(@_importer record)
    @emit "#{ @_globalEventsNamespace }.updated", record
    record

  deleteRecord: (id) ->
    record = @_exporter super(id)
    @emit "#{ @_globalEventsNamespace }.deleted", record
    record

  readRecord: (id) ->
    @_exporter super(id)

  readAllRecords: ->
    @_exporter(r) for r in super()

  countRecords: ->
    @ids().length

  importRecords: (records) ->
    backup = @idExists
    @idExists = RecordStore::idExists
    res = super(records)
    @idExists = backup
    res

  export: (full = no) ->
    {
      config: @exportConfig()
      records: @exportRecords(full)
    }

  exportRecords: (full) ->
    if full
      super()
    else
      backup = @ids
      @ids = RecordStore::ids
      res = super()
      @ids = backup
      res

  ids: (includeDeleted = no) ->
    existing = []
    deleted = []
    for layer in @_layers
      for id in layer.ids() when id not in deleted and id not in existing
        existing.push id
      for id in layer.deletedIds() when id not in deleted and id not in existing
        deleted.push id
    if includeDeleted
      existing.concat(deleted).sort()
    else
      existing.sort()

  deletedIds: ->
    existing = []
    deleted = []
    for layer in @_layers
      for id in layer.ids() when id not in deleted and id not in existing
        existing.push id
      for id in layer.deletedIds() when id not in deleted and id not in existing
        deleted.push id
    deleted.sort()

  _read: (id, keepDeleted = no) ->
    records = @_recordStack id, keepDeleted
    rec = records.shift()
    keys = (key for own key, val of rec)
    for record in records
      for own key, val of record when key not in keys
        keys.push key
        rec[key] = val
    rec

  _update: (meta) ->
    merged = @_importRecord @_read(meta.id)
    for own key, val of meta.record when key isnt 'id'
      merged.record[key] = val
    if @_records.exists meta.id
      merged.metadata = meta.metadata
      super(merged)
    else
      merged.metadata.createdAt = d if (d = meta.metadata.createdAt)
      merged.metadata.updatedAt = meta.metadata.updatedAt
      @_create merged

  _delete: (id, deletedAt) ->
    unless @_records.exists(id)
      rec = @_read id
      e = @_records.deleted(id, deletedAt)
      @_exportRecord rec, {deletedAt: e.value.deletedAt}
    else
      super(id, deletedAt)

  _layersWithRecord: (id, keepDeleted = no) ->
    @assertValidId id
    res = []
    for layer in @_layers when (has = layer.idExists id, yes)
      if has.isDeleted
        res.push(layer) if keepDeleted and res.length is 0
        break
      res.push layer
    res

  _recordStack: (id, keepDeleted = no) ->
    layer._read(id, keepDeleted) for layer in @_layersWithRecord(id, keepDeleted)


module.exports = Class = MergedRecordStore
