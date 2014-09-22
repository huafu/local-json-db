# exports all our classes
for mod in 'utils CoreObject Dictionary DictionaryEx RecordStore MergedRecordStore'.split(' ')
  module.exports[mod] = require './' + mod

