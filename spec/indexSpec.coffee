pkg = require '..'

describe 'local-json-db', ->
  it 'should export public API', ->
    expect(Object.keys pkg).to.deep.equal ['utils', 'Dictionary', 'DictionaryEx', 'RecordStore']
    expect(pkg.utils).to.equal require('../lib/utils')
    expect(pkg.Dictionary).to.equal require('../lib/Dictionary')
    expect(pkg.DictionaryEx).to.equal require('../lib/DictionaryEx')
    expect(pkg.RecordStore).to.equal require('../lib/RecordStore')
