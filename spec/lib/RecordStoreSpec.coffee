{RecordStore} = lib

describe 'RecordStore', ->
  rs = null
  time = Date.now.bind(Date)
  now = time()
  nowStub = null

  beforeEach ->
    nowStub = sinon.stub Date, 'now', -> now

  afterEach ->
    nowStub.restore()


  describe 'without CRUD flags', ->
    beforeEach ->
      rs = new RecordStore([], {
        createdAtKey: no
        updatedAtKey: no
        deletedAtKey: no
      })

    it 'creates a record', ->
      rec = rs.createRecord name: 'Mike'
      expect(rec).to.deep.equal {id: 1, name: 'Mike'}
      expect(-> rs.createRecord 1, name: 'Luke').to.throw()
      rec = rs.createRecord {id: 'dummyId', name: 'Luke'}
      expect(rec).to.deep.equal {id: 'dummyId', name: 'Luke'}
      expect(rs.readRecord 2).to.be.undefined

    it 'reads a record', ->
      rec = rs.createRecord name: 'Mike'
      expect(rs.readRecord 1).to.deep.equal {id: 1, name: 'Mike'}
      rec = rs.createRecord {id: 'dummyId', name: 'Luke'}
      expect(rs.readRecord 'dummyId').to.deep.equal {id: 'dummyId', name: 'Luke'}

    it 'counts records', ->
      expect(rs.countRecords()).to.equal 0
      rs.createRecord name: 'Mike'
      expect(rs.countRecords()).to.equal 1

    it 'updates a record', ->
      rs.createRecord name: 'Mike'
      rec = rs.updateRecord 1, {name: 'John'}
      expect(rec).to.deep.equal {id: 1, name: 'John'}
      expect(rs.readRecord 1).to.deep.equal {id: 1, name: 'John'}
      expect(-> rs.updateRecord 2, {name: 'Luke'}).to.throw()
      expect(rs.readRecord 2).to.be.undefined
      rec.name = 'Huafu'
      rec = rs.updateRecord rec
      expect(rec).to.deep.equal {id: 1, name: 'Huafu'}
      expect(-> rs.updateRecord(2, rec)).to.throw()
      rec.name = undefined
      rec.age = null
      rec = rs.updateRecord rec
      expect(rec).to.deep.equal {id: 1, age: null}

    it 'deletes a record', ->
      expect(-> rs.deleteRecord 1).to.throw()
      rs.createRecord name: 'Mike'
      rs.deleteRecord 1
      expect(rs.readRecord 1).to.be.undefined
      expect(-> rs.deleteRecord 2).to.throw()
      expect(rs.countRecords()).to.equal 0
      expect(-> rs.deleteRecord 1).to.throw()

    it 'imports records', ->
      rs.importRecords [
        {id: 1, name: 'Mike'}
        {id: 3, name: 'Luke'}
        {id: 'stuff', name: 'John'}
      ]
      expect(rs.countRecords()).to.equal 3
      expect(rs.createRecord(name: 'test').id).to.equal 4
      expect(rs.readRecord 1).to.deep.equal {id: 1, name: 'Mike'}
      expect(-> rs.importRecrods [{name: 'Huafu'}]).to.throw()

    it 'exports records', ->
      records = [
        {id: 1, name: 'Mike'}
        {id: 3, name: 'Luke'}
        {id: 'stuff', name: 'John'}
      ]
      rs.importRecords records
      rs.updateRecord 1, name: 'Luke'
      records[0].name = 'Luke'
      rs.deleteRecord 3
      records.splice 1, 1
      rs.createRecord {name: 'Huafu'}
      records.push {id: 4, name: 'Huafu'}
      expect(rs.exportRecords()).to.deep.equal records

    it 'lists ids', ->
      rs.createRecord name: 'Huafu'
      rs.createRecord id: 3, name: 'Mike'
      rs.createRecord name: 'Luke'
      expect(rs.ids()).to.deep.equal ['1', '3', '4']
      rs.deleteRecord 3
      expect(rs.ids()).to.deep.equal ['1', '4']

    it 'lists deleted ids', ->
      rs.createRecord name: 'Huafu'
      rs.createRecord id: 3, name: 'Mike'
      expect(rs.deletedIds()).to.deep.equal []
      rs.deleteRecord 1
      expect(rs.deletedIds()).to.deep.equal ['1']
      rs.deleteRecord 3
      expect(rs.deletedIds()).to.deep.equal ['1', '3']

    it 'resets the whole store', ->
      rs.createRecord name: 'Huafu'
      rs.createRecord id: 3, name: 'Mike'
      rs.createRecord name: 'Luke'
      expect(rs.countRecords()).to.equal 3
      rs.reset()
      expect(rs.countRecords()).to.equal 0

    it 'finds whether an id exists', ->
      rs.createRecord name: 'Huafu'
      expect(rs.idExists 1).to.be.true
      expect(rs.idExists 1, yes).to.be.true
      expect(rs.idExists 2).to.be.false
      expect(rs.idExists 2, yes).to.be.false
      rs.deleteRecord(1)
      expect(rs.idExists(1)).to.be.false
      expect(rs.idExists(1, yes)).to.deep.equal {isDeleted: yes}

    it 'emits record created event', ->
      stub = sinon.stub rs, 'emit'
      rs.createRecord name: 'Huafu'
      expect(stub.calledOnce).to.be.true
      expect(stub.firstCall.args).to.deep.equal ['record.created', {id: 1, name: 'Huafu'}]
      stub.restore()

    it 'emits record updated event', ->
      rs.createRecord name: 'Huafu'
      stub = sinon.stub rs, 'emit'
      rs.updateRecord 1, name: 'Mike'
      expect(stub.calledOnce).to.be.true
      expect(stub.firstCall.args).to.deep.equal ['record.updated', {id: 1, name: 'Mike'}]
      stub.restore()

    it 'emits record deleted event', ->
      rs.createRecord name: 'Huafu'
      stub = sinon.stub rs, 'emit'
      rs.deleteRecord 1
      expect(stub.calledOnce).to.be.true
      expect(stub.firstCall.args).to.deep.equal ['record.deleted', {id: 1, name: 'Huafu'}]
      stub.restore()



  describe 'with CRUD flags', ->
    ts = null

    beforeEach ->
      ts = time() + 1000
      rs = new RecordStore([], {
        createdAtKey: 'c'
        updatedAtKey: 'u'
        deletedAtKey: 'd'
      })

    it 'creates a record', ->
      expect(
        rs.createRecord {name: 'Huafu'}
      ).to.deep.equal {id: 1, name: 'Huafu', c: now, u: now}
      expect(
        rs.createRecord {name: 'Huafu', c: ts}
      ).to.deep.equal {id: 2, name: 'Huafu', c: ts, u: now}
      expect(
        rs.createRecord {name: 'Huafu', u: ts}
      ).to.deep.equal {id: 3, name: 'Huafu', c: now, u: ts}
      expect(
        rs.createRecord {name: 'Huafu', c: ts, u: ts}
      ).to.deep.equal {id: 4, name: 'Huafu', c: ts, u: ts}
      # we should not be able to create a record flagged as deleted
      expect(-> rs.createRecord (name: 'Huafu', d: ts)).to.throw()

    it 'reads a record', ->
      rs.createRecord name: 'Huafu'
      rs.createRecord {name: 'Huafu', c: ts}
      rs.createRecord {name: 'Huafu', u: ts}
      rs.createRecord {name: 'Huafu', c: ts, u: ts}
      expect(rs.readRecord 1).to.deep.equal {id: 1, name: 'Huafu', c: now, u: now}
      expect(rs.readRecord 2).to.deep.equal {id: 2, name: 'Huafu', c: ts, u: now}
      expect(rs.readRecord 3).to.deep.equal {id: 3, name: 'Huafu', c: now, u: ts}
      expect(rs.readRecord 4).to.deep.equal {id: 4, name: 'Huafu', c: ts, u: ts}

    it 'counts records', ->
      expect(rs.countRecords()).to.equal 0
      rs.createRecord name: 'Huafu'
      expect(rs.countRecords()).to.equal 1

    it 'updates a record', ->
      rs.createRecord name: 'Huafu'
      expect(rs.updateRecord 1, {u: ts}).to.deep.equal {id: 1, name: 'Huafu', c: now, u: ts}
      expect(rs.updateRecord 1, {c: ts}).to.deep.equal {id: 1, name: 'Huafu', c: ts, u: now}
      expect(rs.updateRecord 1, {c: ts, u: ts}).to.deep.equal {id: 1, name: 'Huafu', c: ts, u: ts}

    it 'deletes a record', ->
      rs.createRecord name: 'Huafu'
      rs.deleteRecord 1
      expect(rs.readRecord 1).to.be.undefined

    it 'imports records', ->
      rs.importRecords [
        {id: 1, name: 'Mike', c: ts}
        {id: 3, name: 'Luke', d: ts}
        {id: 'stuff', name: 'John', u: ts}
      ]
      expect(rs.countRecords()).to.equal 2
      expect(rs.createRecord(name: 'test').id).to.equal 4
      expect(rs.readRecord 1).to.deep.equal {id: 1, name: 'Mike', c: ts, u: now}
      expect(rs.readRecord 3).to.be.undefined
      expect(rs.readRecord 'stuff').to.deep.equal {id: 'stuff', name: 'John', c: now, u: ts}

    it 'exports records', ->
      records = []
      rs.importRecords [
        {id: 1, name: 'Mike', c: ts}
        {id: 3, name: 'Hector', d: ts}
        {id: 'stuff', name: 'John', u: ts}
      ]
      rs.updateRecord 1, name: 'Luke'
      records.push {id: 1, name: 'Luke', c: ts, u: now}
      rs.createRecord {name: 'Huafu'}
      records.push {id: 4, name: 'Huafu', c: now, u: now}
      # then comes the deleted ones
      records.push {id: '3', d: ts}
      rs.deleteRecord 'stuff'
      records.push {id: 'stuff', d: now}
      expect(rs.exportRecords()).to.deep.equal records

    it 'lists ids', ->
      rs.createRecord name: 'Huafu'
      rs.createRecord id: 3, name: 'Mike'
      rs.createRecord name: 'Luke'
      expect(rs.ids()).to.deep.equal ['1', '3', '4']
      rs.deleteRecord 3
      expect(rs.ids()).to.deep.equal ['1', '4']
      expect(rs.ids(yes)).to.deep.equal ['1', '4', '3']

    it 'lists deleted ids', ->
      rs.createRecord name: 'Huafu'
      rs.createRecord id: 3, name: 'Mike'
      expect(rs.deletedIds()).to.deep.equal []
      rs.deleteRecord 1
      expect(rs.deletedIds()).to.deep.equal ['1']
      rs.deleteRecord 3
      expect(rs.deletedIds()).to.deep.equal ['1', '3']


    it 'resets the whole store', ->
      rs.createRecord name: 'Huafu'
      rs.createRecord id: 3, name: 'Mike'
      rs.createRecord name: 'Luke'
      expect(rs.countRecords()).to.equal 3
      rs.reset()
      expect(rs.countRecords()).to.equal 0

    it 'finds whether an id exists', ->
      rs.createRecord name: 'Huafu'
      expect(rs.idExists 1).to.be.true
      expect(rs.idExists 1, yes).to.be.true
      expect(rs.idExists 2).to.be.false
      expect(rs.idExists 2, yes).to.be.false
      rs.deleteRecord(1)
      expect(rs.idExists(1)).to.be.false
      expect(rs.idExists(1, yes)).to.deep.equal {isDeleted: yes}

    it 'emits record created event', ->
      stub = sinon.stub rs, 'emit'
      rs.createRecord name: 'Huafu'
      expect(stub.calledOnce).to.be.true
      expect(stub.firstCall.args).to.deep.equal ['record.created', {id: 1, name: 'Huafu', c: now, u: now}]
      stub.restore()

    it 'emits record updated event', ->
      rs.createRecord name: 'Huafu'
      stub = sinon.stub rs, 'emit'
      rs.updateRecord 1, name: 'Mike'
      expect(stub.calledOnce).to.be.true
      expect(stub.firstCall.args).to.deep.equal ['record.updated', {id: 1, name: 'Mike', c: now, u: now}]
      stub.restore()

    it 'emits record deleted event', ->
      rs.createRecord name: 'Huafu'
      stub = sinon.stub rs, 'emit'
      rs.deleteRecord 1
      expect(stub.calledOnce).to.be.true
      expect(stub.firstCall.args).to.deep.equal ['record.deleted', {id: 1, name: 'Huafu', d: now}]
      stub.restore()



