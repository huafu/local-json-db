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

  clear: (withDeleted = yes) ->
    @deletedClear() if withDeleted
    @_clearing = yes
    super
    delete @_clearing
    @

  count: (withDeleted = no) ->
    res = super()
    res += @_deleted.length if withDeleted
    res

  deletedCount: ->
    @_deleted.count()

  deletedClear: ->
    @_deleted.clear()
    @

  deletedKeys: ->
    @_deleted.keys()

  deletedUnset: (key) ->
    @_deleted.unset key

  deletedExists: (key) ->
    @_deleted.exists key

  deleted: (key, deletedAt = null) ->
    k = @_stringifyKey key
    @assert (k not in @_keys and k not in @_deleted._keys), "entry already exists, use `deletedAt()` instead"
    @_deleted.set k, {deletedAt: @_parseDate(deletedAt)}

  entryForKey: (key) ->
    if (e = super).index is -1 and (deleted = @_deleted.entryForKey key).index isnt -1
      e.metadata = deleted.value
    e

  createdAt: (key, date) ->
    e = @entryForKey key
    if arguments.length is 2
      @assert (e.index >= 0), "no entry for key #{key}"
      e.metadata.createdAt = @_parseDate date
    else
      e.metadata?.createdAt

  updatedAt: (key, date) ->
    e = @entryForKey key
    if arguments.length is 2
      @assert (e.index >= 0), "no entry for key #{key}"
      e.metadata.updatedAt = @_parseDate date
    else
      e.metadata?.updatedAt

  deletedAt: (key, date) ->
    e = @entryForKey key
    if arguments.length is 2
      if e.index >= 0
        @_unset(e.index, yes, date).metadata.deletedAt
      else
        @assert (e.metadata), "no entry for key #{key}"
        e.metadata.deletedAt = @_parseDate date
    else
      e.metadata?.deletedAt

  toKeyValuePairs: (keys = {}, _complete = ->) ->
    utils.defaults keys, {metadata: 'metadata'}
    super keys, (o, i) =>
      o[keys.metadata] = @_metadata[i] if keys.metadata
      _complete o, i

  deletedMetadata: (asObject = no) ->
    if asObject
      @_deleted.export()
    else
      @_deleted.toKeyValuePairs value: 'metadata'

  _unset: (index, emitEvent = yes, _now = null) ->
    e = super index, no
    if e.index >= 0
      if @_clearing
        @_metadata.splice e.index, 1
        e.metadata.deletedAt = @_parseDate _now
      else
        de = @_deleted.set e.key, {deletedAt: @_parseDate _now}
        @_metadata.splice e.index, 1
        Object.defineProperty(
          e.metadata,
          'deletedAt',
          {
            get: -> de.deletedAt
            set: (date) => de.deletedAt = @_parseDate(date)
          }
        )
      @emit('entry.unset', e) if emitEvent
    e

  _set: (index, key, value, emitEvent = yes, _now = null) ->
    ts = @_parseDate _now
    e = super index, key, value, no
    unless e.metadata
      @_metadata[e.index] = e.metadata = {createdAt: ts, updatedAt: ts}
      @_deleted.unset key
    else
      e.metadata.updatedAt = ts
    @emit('entry.set', e) if emitEvent
    e

  _entryForIndex: (index) ->
    e = super index
    if e.index isnt -1
      e.metadata = @_metadata[e.index]
    e

  _parseDate: (date) ->
    if date is null
      Date.now()
    else if utils.isNumber(date)
      Math.round(date)
    else
      (new Date date).getTime()



module.exports = Class = DictionaryEx
