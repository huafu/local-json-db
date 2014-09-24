# exports all our classes
for mod in 'utils CoreObject Dictionary DictionaryEx RecordStore MergedRecordStore Model Database'.split(' ')
  module.exports[mod] = require './' + mod

