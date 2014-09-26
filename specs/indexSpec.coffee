describe 'local-json-db', ->
  it 'should export public API', ->
    expect(Object.keys lib).to.deep.equal [
      'utils', 'CoreObject', 'Dictionary', 'DictionaryEx', 'RecordStore', 'MergedRecordStore',
      'Model', 'ModelAttribute', 'Relationship', 'ModelEx', 'Database'
    ]
    expect(lib.utils).to.equal require('../src/utils')
    expect(lib.CoreObject).to.equal require('../src/CoreObject')
    expect(lib.Dictionary).to.equal require('../src/Dictionary')
    expect(lib.DictionaryEx).to.equal require('../src/DictionaryEx')
    expect(lib.RecordStore).to.equal require('../src/RecordStore')
    expect(lib.MergedRecordStore).to.equal require('../src/MergedRecordStore')
    expect(lib.Model).to.equal require('../src/Model')
    expect(lib.ModelAttribute).to.equal require('../src/ModelAttribute')
    expect(lib.Relationship).to.equal require('../src/Relationship')
    expect(lib.ModelEx).to.equal require('../src/ModelEx')
    expect(lib.Database).to.equal require('../src/Database')
