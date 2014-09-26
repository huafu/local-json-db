###*
  Local JSON database with overlays

  @project local-json-db
  @title Local JSON DB
  @url https://github.com/huafu/local-json-db
  @author Huafu Gandon <huafu.gandon@gmail.com>
###

all = [
  'utils', 'CoreObject', 'Dictionary', 'DictionaryEx', 'RecordStore', 'MergedRecordStore', 'Model',
  'Database', 'Relationship', 'ModelEx'
]

# exports all our classes
for mod in all
  module.exports[mod] = require './' + mod

