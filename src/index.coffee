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
  module.exports[mod] = require './' + mod

