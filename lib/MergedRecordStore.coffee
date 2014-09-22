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
    record = super
    @emit "#{ @_globalEventsNamespace }.deleted", record
    record


  _read: (id) ->
    utils.merge @_recordStack(id)...

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

  _layersWithRecord: (id) ->
    @assertValidId id
    res = []
    for layer in @_layers when (has = layer.idExists id, yes)
      break if has.isDeleted
      res.push layer
    res

  _recordStack: (id) ->
    layer.readRecord(id) for layer in @_layersWithRecord(id)


module.exports = Class = MergedRecordStore
