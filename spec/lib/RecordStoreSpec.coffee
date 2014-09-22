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
      rs = new RecordStore()

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

    it 'ids', ->
      rs.createRecord name: 'Huafu'
      rs.createRecord id: 3, name: 'Mike'
      rs.createRecord name: 'Luke'
      expect(rs.ids()).to.deep.equal ['1', '3', '4']
      rs.deleteRecord 3
      expect(rs.ids()).to.deep.equal ['1', '4']

    it 'resets the whole store', ->
      rs.createRecord name: 'Huafu'
      rs.createRecord id: 3, name: 'Mike'
      rs.createRecord name: 'Luke'
      expect(rs.countRecords()).to.equal 3
      rs.reset()
      expect(rs.countRecords()).to.equal 0



