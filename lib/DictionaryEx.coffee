utils = require './utils'
Dictionary = require './Dictionary'

Class = null



class DictionaryEx extends Dictionary
  _metadata: null
  _deleted: null

  constructor: (data = {}, options = {})->
    @_metadata = []
    @_deleted = new Dictionary({}, options)
    @lockProperties '_metadata', '_deleted'
    super

  deletedKeys: ->
    @_deleted.keys()

  deletedUnset: (key) ->
    @_deleted.unset key

  deletedExists: (key) ->
    @_deleted.exists key

  entryForKey: (key) ->
    if (e = super).index is -1 and (deleted = @_deleted.entryForKey key).index isnt -1
      e.metadata = utils.copy deleted.value
    e

  createdAt: (key) ->
    @entryForKey(key).metadata?.createdAt

  updatedAt: (key) ->
    @entryForKey(key).metadata?.updatedAt

  deletedAt: (key) ->
    @entryForKey(key).metadata?.deletedAt

  toKeyValuePairs: (keys = {}, _complete = ->) ->
    utils.defaults keys, {metadata: 'metadata'}
    super keys, (o, i) =>
      o[keys.metadata] = utils.copy(@_metadata[i]) if keys.metadata
      _complete o, i

  deletedMetadata: (asObject = no) ->
    if asObject
      @_deleted.export()
    else
      @_deleted.toKeyValuePairs value: 'metadata'

  _unset: (index, emitEvent = yes) ->
    e = super index, no
    if e.index >= 0
      e.metadata.deletedAt = Date.now()
      @_deleted.set e.key, utils.copy(e.metadata)
      @_metadata.splice e.index, 1
      @emit('entry.unset', e) if emitEvent
    e

  _set: (index, key, value, emitEvent = yes) ->
    ts = Date.now()
    e = super index, key, value, no
    unless e.metadata
      @_metadata[e.index] = utils.copy(e.metadata = {createdAt: ts, updatedAt: ts})
      @_deleted.unset key
    else
      @_metadata[e.index].updatedAt = e.metadata.updatedAt = ts
    @emit('entry.set', e) if emitEvent
    e

  _entryForIndex: (index) ->
    e = super index, no
    if e.index isnt -1
      e.metadata = utils.copy @_metadata[e.index]
    e



module.exports = Class = DictionaryEx
