
###*
  Local JSON database with overlays

  @project local-json-db
  @title Local JSON DB
  @url https://github.com/huafu/local-json-db
  @author Huafu Gandon <huafu.gandon@gmail.com>
###

# exports all our classes
for mod in 'utils CoreObject Dictionary DictionaryEx RecordStore MergedRecordStore Model Database'.split(' ')
  module.exports[mod] = require './' + mod

