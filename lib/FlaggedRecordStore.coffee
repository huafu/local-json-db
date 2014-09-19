RecordStore = require './RecordStore'
Class = null


class FlaggedRecordStore extends RecordStore

  countRecords: (virtual = yes) ->
    if virtual
      super()
    else
      Object.keys(@load()._records).length

  readRecord: (id, virtual = yes) ->
    if virtual
      super
    else
      Class.copy @load()._records[Class.coerceId id]

  _readRecord: (rid) ->
    if (rec = super) and rec.__deleted
      null
    else
      rec

  _deleteRecord: (rid) ->
    @_writeRecord rid, null, {__deleted: yes}, yes

module.exports = Class = FlaggedRecordStore
