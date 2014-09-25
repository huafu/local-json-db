describe 'local-json-db', ->
  it 'should export public API', ->
    expect(Object.keys lib).to.deep.equal [
      'utils', 'CoreObject', 'Dictionary', 'DictionaryEx', 'RecordStore', 'MergedRecordStore',
      'Model', 'Database'
    ]
    expect(lib.utils).to.equal require('../lib/utils')
    expect(lib.CoreObject).to.equal require('../lib/CoreObject')
    expect(lib.Dictionary).to.equal require('../lib/Dictionary')
    expect(lib.DictionaryEx).to.equal require('../lib/DictionaryEx')
    expect(lib.RecordStore).to.equal require('../lib/RecordStore')
    expect(lib.MergedRecordStore).to.equal require('../lib/MergedRecordStore')
    expect(lib.Model).to.equal require('../lib/Model')
    expect(lib.Database).to.equal require('../lib/Database')
