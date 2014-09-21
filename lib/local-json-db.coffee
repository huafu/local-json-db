# exports all our classes
for mod in 'utils CoreObject Dictionary DictionaryEx RecordStore'.split(' ')
  module.exports[mod] = require './' + mod

