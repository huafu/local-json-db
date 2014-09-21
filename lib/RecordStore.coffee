sysPath = require 'path'
fs = require 'fs'

utils = require './utils'
CoreObject = require './CoreObject'
DictionaryEx = require './DictionaryEx'

Class = null

class RecordStore extends CoreObject
  _records: null
  _config: null
  _lastId: null

  constructor: (records = [], config = {}) ->
    @_records = new DictionaryEx({}, {stringifyKeys: yes})
    @_config = config
    @_lastId = 0
    @lockProperties '_records', '_config'
    @createRecords records

  createRecords: (records) ->
    utils.map records, (record) => @createRecord(record)

  createRecord: (record = {}) ->
    @assertValidRecord record
    if (id = record.id)?
      @assert (not @_records.exists id), "a record with id #{ id } already exists"
    else
      id = record.id ?= ++@_lastId
    @_records.set id, @copyRecord(record)
    record

  updateRecord: (id, record) ->


  assertValidRecord: (record, mustHaveId = no) ->
    record and utils.isObject(record) and (not mustHaveId or record.id?)



  copyRecord: (obj) ->
    res = utils.copy obj
    if res?.id?
      utils.lock res, 'id'
    res



module.exports = Class = RecordStore
