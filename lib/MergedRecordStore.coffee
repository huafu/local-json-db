utils = require './utils'
CoreObject = require './CoreObject'
RecordStore = require './RecordStore'

Class = null

class MergedRecordStore extends RecordStore
  _layers: null
  _coreLayer: null
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
    delete @_config.eventsNamespace
    @_layers = []
    @_lastId = 0
    @addLayer records, {}
    @_coreLayer = @_layers[0]
    @_records = @_coreLayer._records
    @_eventsNamespace = @_coreLayer._eventsNamespace
    @lockProperties(
      '_layers', '_eventsNamespace', '_coreLayer', '_records', '_config', '_globalEventsNamespace'
    )

  addLayer: (records = [], config = {}) ->
    # be sure the other layers follow our config
    conf = utils.defaults {
      eventsNamespace: "layer#{ @_layers.length }.#{ config.eventsNamespace ? @_eventsNamespace }"
    }, @_config, config
    @_layers.push (rs = new RecordStore(records, conf))
    @_lastId = Math.max @_lastId, rs.lastAutoId()
    @

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
    utils.merge @_recordStack(id, keepDeleted)...

  _update: (meta) ->
    if @_records.exists meta.id
      super @_read(meta.id)
    else
      @_create @_read(meta.id)
    super

  _delete: (id) ->
    unless @_records.exist(id)
      @_create @_read(id)
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
