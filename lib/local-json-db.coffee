# be sure to import in good order
utils = require './utils'
CoreObject = require './CoreObject'
RecordStore = require './RecordStore'
FlaggedRecordStore = require './FlaggedRecordStore'

# export our public API
module.exports = {
  utils
  RecordStore: FlaggedRecordStore
}
