utils = require './utils'
CoreObject = require './CoreObject'
RecordStore = require './RecordStore'

Class = null

class MergedRecordStore extends RecordStore
  _layers: null
  _eventsNamespace: null
  _globalEventsNamespace: null

  constructor: (records = [], config = {}) ->
    @_config = utils.defaults {}, config, {
      createdAtKey: no
      updatedAtKey: no
      deletedAtKey: no
      eventsNamespace: 'record'
    }
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

  addLayer: (records = [], config = {}) ->
    # be sure the other layers follow our config
    conf = utils.defaults {
      eventsNamespace: "layer#{ @_layers.length }.#{ config.eventsNamespace ? @_globalEventsNamespace }"
      eventsEmitter: @
    }, @_config, config
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
    record = super
    @emit "#{ @_globalEventsNamespace }.created", record
    record

  updateRecord: (id, record) ->
    record = super
    @emit "#{ @_globalEventsNamespace }.updated", record
    record

  deleteRecord: (id) ->
    record = super(id)
    @emit "#{ @_globalEventsNamespace }.deleted", record
    record

  countRecords: ->
    @ids().length

  importRecords: (records) ->
    backup = @idExists
    @idExists = RecordStore::idExists
    res = super(records)
    @idExists = backup
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
      existing.concat(deleted)
    else
      existing

  deletedIds: ->
    existing = []
    deleted = []
    for layer in @_layers
      for id in layer.ids() when id not in deleted and id not in existing
        existing.push id
      for id in layer.deletedIds() when id not in deleted and id not in existing
        deleted.push id
    deleted

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
    upd = meta.record
    meta.record = @_read(meta.id)
    for own key, val of upd when key isnt 'id'
      meta.record[key] = val
    if @_records.exists meta.id
      super(meta)
    else
      @_create meta

  _delete: (id) ->
    unless @_records.exists(id)
      @_create @_importRecord(@_read id)
    super

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
