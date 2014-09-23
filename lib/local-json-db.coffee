# exports all our classes
for mod in 'utils CoreObject Dictionary DictionaryEx RecordStore MergedRecordStore Database Model'.split(' ')
  module.exports[mod] = require './' + mod

