utils = require './utils'
CoreObject = require './CoreObject'

Class = null

class Dictionary extends CoreObject
  _keys: null
  _values: null
  _stringifyKeys: null
  _undefinedUnsets: null
  length: null

  constructor: (data = {}, options = {}) ->
    return new Class(arguments...) unless @ instanceof Class
    @_stringifyKeys = Boolean(options.stringifyKeys)
    @_undefinedUnsets = Boolean(options.undefinedUnsets)
    @_keys = []
    @_values = []
    @lockProperties '_stringifyKeys', '_undefinedUnsets', '_keys', '_values'
    @import data
    @


  indexOfKey: (key) ->
    @entryForKey(key).index

  indexOfValue: (value, onlyFirst = yes) ->
    if onlyFirst
      @entryForValue(value).index
    else
      (e.index for e in @entriesForValue(value))

  clear: ->
    while @_keys.length
      @_unset(@_keys.length - 1)
    @

  import: (data, clear = no) ->
    @clear() if clear
    for own key, val of data
      @set key, val
    @

  export: ->
    @assert @_stringifyKeys, "cannot export a dictionary to a bare object if the keys aren't of type string"
    res = {}
    for k, i in @_keys
      res[k] = @_values[i]
    res

  toKeyValuePairs: (keys = {}, _complete = ->) ->
    utils.defaults keys, {key: 'key', value: 'value', index: no}
    res = []
    for k, i in @_keys
      o = {}
      o[keys.index] = i if keys.index
      o[keys.key] = k if keys.key
      o[keys.value] = @_values[i] if keys.value
      _complete o, i
      res.push o
    res

  keys: ->
    @_keys.slice()

  values: ->
    @_values.slice()

  count: ->
    @_keys.length

  set: (key, value) ->
    e = @entryForKey key
    del = value is undefined and @_undefinedUnsets
    if del
      unless e.index is -1
        e = @_unset e.index
    else
      e = @_set e.index, key, value
    e

  get: (key) ->
    @entryForKey(key).value

  exists: (key) ->
    Boolean(@entryForKey(key).index >= 0)

  contains: (value) ->
    Boolean(@entryForValue(value).index >= 0)

  unset: (key) ->
    @_unset(@entryForKey(key).index)

  map: (callback) ->
    if utils.isString(callback)
      cb = (e) -> e.value?[callback]
    else
      cb = callback
    res = []
    for i in [0...@_keys.length]
      res.push cb(@_entryForIndex(i), @)
    res

  collect: (callback) ->
    if utils.isString(callback)
      cb = (e) -> e.value?[callback]
    else
      cb = callback
    res = []
    for i in [0...@_keys.length]
      if (d = cb @_entryForIndex(i), @) isnt undefined
        res.push d
    res

  entryForKey: (key) ->
    @_entryForIndex @_keys.indexOf(@_stringifyKey key)

  entryForValue: (value) ->
    @_entryForIndex @_values.indexOf(value)

  entriesForValue: (value) ->
    @_entryForIndex(i) for v, i in @_values when v is value

  stringifyKey: (key) ->
    "#{key}"

  toJSON: ->
    @export()

  _entryForIndex: (index) ->
    if index >= 0
      key = @_keys[index]
      value = @_values[index]
      e = {index, key, value}
    else
      index = -1
      e = {index}
    e

  _unset: (index, emitEvent = yes) ->
    e = @_entryForIndex index
    if e.index >= 0
      @_keys.splice e.index, 1
      @_values.splice e.index, 1
      @emit('entry.unset', e) if emitEvent
    e

  _set: (index, key, value, emitEvent = yes) ->
    if index is -1
      index = @_keys.length
      @_keys[index] = @_stringifyKey(key)
    @_values[index] = value
    entry = @_entryForIndex index
    @emit('entry.set', entry) if emitEvent
    entry

  _stringifyKey: (key) ->
    if @_stringifyKeys and typeof key isnt 'string'
      @stringifyKey key
    else
      key

Object.defineProperties(
  Dictionary.prototype
  {
    length: configurable: no, get: (-> @count()), set: (-> throw new Error("length property is read-only"))
  }
)

module.exports = Class = Dictionary
