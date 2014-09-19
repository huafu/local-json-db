pkg = require '..'

describe 'local-json-db', ->
  it 'should export public API', ->
    expect(Object.keys pkg).to.deep.equal ['utils', 'RecordStore']
    expect(pkg.utils).to.equal require('../lib/utils')
    expect(pkg.RecordStore).to.equal require('../lib/FlaggedRecordStore')
