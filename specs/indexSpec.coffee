describe 'local-json-db', ->
  it 'should export public API', ->
    expect(Object.keys lib).to.deep.equal [
      'utils', 'CoreObject', 'Dictionary', 'DictionaryEx', 'RecordStore', 'MergedRecordStore',
      'Model', 'ModelAttribute', 'Relationship', 'ModelEx', 'Database'
    ]
    expect(lib.utils).to.equal require(LIB_PATH + '/utils')
    expect(lib.CoreObject).to.equal require(LIB_PATH + '/CoreObject')
    expect(lib.Dictionary).to.equal require(LIB_PATH + '/Dictionary')
    expect(lib.DictionaryEx).to.equal require(LIB_PATH + '/DictionaryEx')
    expect(lib.RecordStore).to.equal require(LIB_PATH + '/RecordStore')
    expect(lib.MergedRecordStore).to.equal require(LIB_PATH + '/MergedRecordStore')
    expect(lib.Model).to.equal require(LIB_PATH + '/Model')
    expect(lib.ModelAttribute).to.equal require(LIB_PATH + '/ModelAttribute')
    expect(lib.Relationship).to.equal require(LIB_PATH + '/Relationship')
    expect(lib.ModelEx).to.equal require(LIB_PATH + '/ModelEx')
    expect(lib.Database).to.equal require(LIB_PATH + '/Database')
