describe 'local-json-db', ->
  it 'should export public API', ->
    expect(Object.keys lib).to.deep.equal ['utils', 'CoreObject', 'Dictionary', 'DictionaryEx', 'RecordStore']
    expect(lib.utils).to.equal require('../lib/utils')
    expect(lib.CoreObject).to.equal require('../lib/CoreObject')
    expect(lib.Dictionary).to.equal require('../lib/Dictionary')
    expect(lib.DictionaryEx).to.equal require('../lib/DictionaryEx')
    expect(lib.RecordStore).to.equal require('../lib/RecordStore')
