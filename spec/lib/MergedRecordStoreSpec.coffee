{MergedRecordStore, RecordStore} = lib

describe 'MergedRecordStore', ->
  rs = null
  time = Date.now.bind(Date)
  now = time()
  afterNow = now + 1000
  nowStub = null

  beforeEach ->
    nowStub = sinon.stub Date, 'now', -> now

  afterEach ->
    nowStub.restore()

  it 'adds a layer', ->
    rs = new MergedRecordStore()
    expect(rs.layers()).to.have.length 1
    expect(rs.layers(0)).to.be.instanceof RecordStore
    rs.addLayer()
    expect(rs.layers()).to.have.length 2
    expect(rs.layers(1)).to.be.instanceof RecordStore

  it 'removes a layer', ->
    rs = new MergedRecordStore()
    expect(-> rs.removeLayer(0)).to.throw()
    rs.addLayer()
    rs.removeLayer(1)
    expect(rs.layers()).to.have.length 1


  describe 'with only one layer', ->
    beforeEach ->
      rs = new MergedRecordStore([
        {id: 1, name: 'Huafu', u: afterNow}
        {id: 2, name: 'Mike'}
        {id: 3, d: afterNow}
      ], {
        createdAtKey: 'c'
        updatedAtKey: 'u'
        deletedAtKey: 'd'
      })

    it 'reads a record', ->
      expect(rs.readRecord 1).to.deep.equal {
        id: 1, name: 'Huafu', c: now, u: afterNow
      }
      expect(rs.readRecord 2).to.deep.equal {
        id: 2, name: 'Mike', c: now, u: now
      }
      expect(rs.readRecord 3).to.be.undefined

    it 'creates a record', ->
      exp = {
        id: 4, name: 'Hector', c: now, u: now
      }
      expect(rs.createRecord name: 'Hector').to.deep.equal exp
      expect(rs.readRecord 4).to.deep.equal exp

    it 'updates a record'
    it 'deletes a record'
    it 'imports some records'
    it 'exports all records'
    it 'lists all IDs'
    it 'lists deleted IDs'
    it 'emits layer events'
    it 'emits record events'
