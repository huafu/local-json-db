###*
  Local JSON database with overlays

  @project local-json-db
  @title Local JSON DB
  @url https://github.com/huafu/local-json-db
  @author Huafu Gandon <huafu.gandon@gmail.com>
###

all = [
  'utils', 'CoreObject', 'Dictionary', 'DictionaryEx', 'RecordStore', 'MergedRecordStore', 'Model',
  'ModelAttribute', 'Relationship', 'ModelEx', 'Database'
]

# exports all our classes
for mod in all
  try
    module.exports[mod] = require './new/' + mod
  catch e
    if e.code is 'MODULE_NOT_FOUND'
      module.exports[mod] = require './' + mod
    else
      throw e

