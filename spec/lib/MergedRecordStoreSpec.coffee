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

    it 'updates a record', ->
      exp = {
        id: 2, name: 'Huafu', u: afterNow
      }
      rs.updateRecord exp
      exp.c = now
      expect(rs.readRecord 2).to.deep.equal exp
      expect(-> rs.updateRecord 'dummy', {}).to.throw()

    it 'deletes a record', ->
      expect(rs.deleteRecord 1).to.deep.equal id: 1, name: 'Huafu', d: now
      expect(-> rs.deleteRecord 'dummy').to.throw()

    it 'imports some records', ->
      rs.importRecords [
        {id: 5, name: 'Kenny'}
        {id: 6, d: now}
        {id: 7, name: 'Noy', u: afterNow}
      ]
      expect(rs.readRecord(5)).to.deep.equal {
        id: 5, name: 'Kenny', c: now, u: now
      }
      expect(rs.readRecord(6)).to.be.undefined
      expect(rs.readRecord(7)).to.deep.equal {
        id: 7, name: 'Noy', c: now, u: afterNow
      }
      expect(-> rs.importRecords [
        {id: 1, name: 'Test'}
      ]).to.throw()
      expect(-> rs.importRecords [
        {id: 6, name: 'Test'}
      ]).to.not.throw()
      expect(rs.readRecord(6)).to.deep.equal {id: 6, name: 'Test', c: now, u: now}

    it 'exports all records', ->
      expect(rs.exportRecords()).to.deep.equal [
        {id: 1, name: 'Huafu', c: now, u: afterNow}
        {id: 2, name: 'Mike', c: now, u: now}
        {id: '3', d: afterNow}
      ]

    it 'lists all IDs', ->
      expect(rs.ids()).to.deep.equal ['1', '2']
      expect(rs.ids(yes)).to.deep.equal ['1', '2', '3']
      rs.deleteRecord(1)
      expect(rs.ids()).to.deep.equal ['2']
      expect(rs.ids(yes)).to.deep.equal ['2', '3', '1']

    it 'lists deleted IDs', ->
      expect(rs.deletedIds()).to.deep.equal ['3']
      rs.deleteRecord(1)
      expect(rs.deletedIds()).to.deep.equal ['3', '1']


    describe 'events', ->
      emitStub = null
      beforeEach ->
        emitStub = sinon.stub rs, 'emit'
      afterEach ->
        emitStub.restore()

      it 'emits record created event', ->
        rec = rs.createRecord name: 'Adam'
        expect(emitStub.callCount).to.equal 2
        expect(emitStub.getCall(0).args).to.deep.equal [
          'layer0.record.created', rec
        ]
        expect(emitStub.getCall(1).args).to.deep.equal [
          'record.created', rec
        ]

      it 'emits record updated event', ->
        rec = rs.updateRecord id: 1, name: 'Jane'
        expect(emitStub.callCount).to.equal 2
        expect(emitStub.getCall(0).args).to.deep.equal [
          'layer0.record.updated', rec
        ]
        expect(emitStub.getCall(1).args).to.deep.equal [
          'record.updated', rec
        ]

      it 'emits record deleted event', ->
        rec = rs.deleteRecord 1
        expect(emitStub.callCount).to.equal 2
        expect(emitStub.getCall(0).args).to.deep.equal [
          'layer0.record.deleted', rec
        ]
        expect(emitStub.getCall(1).args).to.deep.equal [
          'record.deleted', rec
        ]


