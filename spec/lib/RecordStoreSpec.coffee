RecordStore = require '../../lib/RecordStore'
sysPath = require 'path'

newRecordStore = (path, options) ->
  new RecordStore jsonPath(path), options

describe 'RecordStore', ->
  rs = null

  beforeEach ->
    rs = newRecordStore 'user'

  describe 'writable', ->
    it 'should read JSON', ->
      expect(rs.readJSON()).to.deep.equal jsonRecord('user')

    it 'should not load invalid data', ->
      rs = null
      expect(-> rs = newRecordStore('invalid')).to.not.throw()
      expect(-> rs.load()).to.throw()

    it 'should load valid data', ->
      expect(-> rs.load()).to.not.throw()
      expect(rs.path).to.equal jsonPath('user', yes)
      rs = newRecordStore('post')
      expect(-> rs.load()).to.not.throw()
      expect(rs.path).to.equal jsonPath('post', yes)

    it 'should return the loaded status', ->
      expect(rs.isLoaded()).to.be.false
      rs.load()
      expect(rs.isLoaded()).to.be.true

    it 'should count records', ->
      expect(rs.countRecords()).to.equal 3
      expect(newRecordStore('post').countRecords()).to.equal 2

    it 'should know the last free auto-id', ->
      expect(rs.load()._lastId).to.equal 6
      expect(newRecordStore('post').load()._lastId).to.equal 2

    it 'should read record by id', ->
      expect(rs.readRecord(1)).to.deep.equal jsonRecord('user', 1)
      expect(rs.readRecord(2)).to.deep.equal jsonRecord('user', 2)
      expect(rs.readRecord(6)).to.deep.equal jsonRecord('user', 6)

    it 'should not read unknown record', ->
      expect(rs.readRecord 10).to.be.undefined
      expect(rs.readRecord 20).to.be.undefined

    it 'should lock the value of a record id', ->
      r = rs.readRecord(1)
      expect(-> r.id = 10).to.throw()
      expect(-> r.name = "Some Name").to.not.throw()

    it 'should always get copy of records', ->
      r1 = rs.readRecord(1)
      r2 = rs.readRecord(1)
      expect(r1).to.not.equal r2
      r1.name = "Luke"
      expect(rs.readRecord(1).name).to.equal 'Huafu Gandon'

    it 'should create new records', ->
      record1 = {
        id:   7
        name: "Cyril"
      }
      record2 = {
        id:   12
        name: "Hector"
      }
      record3 = {id: 13}
      expect(rs.createRecord name: "Cyril").to.deep.equal record1
      expect(rs.createRecord id: 12, name: "Hector").to.deep.equal record2
      expect(rs.createRecord()).to.deep.equal record3
      expect(rs.readRecord(7)).to.deep.equal record1
      expect(rs.readRecord(12)).to.deep.equal record2
      expect(rs.readRecord(13)).to.deep.equal record3

    it 'should not create record with existing or invalid id', ->
      expect(-> rs.createRecord id: 0).to.throw()
      expect(-> rs.createRecord id: 6).to.throw()

    it 'should delete record by id', ->
      rs.deleteRecord(1)
      expect(rs.readRecord 1).to.be.undefined
      rs.deleteRecord(6)
      expect(rs.readRecord 6).to.be.undefined

    it 'should not delete undefined record', ->
      expect(-> rs.deleteRecord 10).to.throw()
      expect(-> rs.deleteRecord 10, no).to.not.throw()

    it 'should update a record', ->
      r = rs.readRecord(1)
      r.name = 'Luke'
      r.isClaimed = no
      r.joinedAt = undefined
      r.dummy = null
      upd = {
        id:        1
        name:      'Luke'
        isClaimed: no
        dummy: null
      }
      expect(rs.updateRecord r).to.deep.equal upd
      expect(rs.readRecord 1).to.deep.equal upd
      upd = {
        id: 2
        name: 'Pattiya Chamniphan'
        isClaimed: no
        dummy: null
      }
      expect(rs.updateRecord 2, {isClaimed: no, joinedAt: undefined, dummy: null}).to.deep.equal upd
      expect(rs.readRecord 2).to.deep.equal upd


    it 'should write changes when saving', ->
      orig = rs.readJSON()
      stub = sinon.stub rs, 'writeJSON'
      # change some stuff
      rs.updateRecord(1, name: "Julian")
      orig.records[0].name = "Julian"
      rs.deleteRecord(6)
      orig.records.pop()
      rs.createRecord name: "Bam"
      orig.records.push id: 7, name: "Bam"
      rs.save()
      expect(stub.calledOnce).to.be.true
      expect(stub.getCall(0).args[0]).to.deep.equal orig


  describe 'read only', ->
    rs = null
    beforeEach ->
      rs = newRecordStore('user', readOnly: yes)

    it 'should fail when trying to update a record', ->
      expect(-> rs.updateRecord(1, {name: "Lilian"})).to.throw()

    it 'should fail when trying to create a record', ->
      expect(-> rs.createRecord name: "Tor").to.throw()

    it 'should fail when trying to delete a record', ->
      expect(-> rs.deleteRecord 1).to.throw()

    it 'should fail when trying to save', ->
      expect(-> rs.save()).to.throw()


  describe 'events', ->
    rs = null
    emitStub = null
    beforeEach ->
      rs = newRecordStore('user')
      emitStub = sinon.stub rs, 'emit'
    afterEach ->
      emitStub.restore()
      emitStub = null

    it 'should trigger the load event', ->
      rs.load()
      expect(emitStub.lastCall.args).to.deep.equal ['loaded', 3]

    it 'should trigger the record created event', ->
      rs.createRecord(name: 'Albert')
      expect(emitStub.lastCall.args).to.deep.equal ['record.created', {id: 7, name: 'Albert'}]

    it 'should trigger the record deleted event', ->
      rs.deleteRecord(6)
      expect(emitStub.lastCall.args).to.deep.equal ['record.deleted', {id: 6, name: 'John Doh', isClaimed: no}]

    it 'should trigger the record updated event', ->
      rs.updateRecord(6, name: 'Mike')
      expect(emitStub.lastCall.args).to.deep.equal [
        'record.updated'
        {id: 6, name: 'Mike', isClaimed: no}
        {id: 6, name: 'John Doh', isClaimed: no}
      ]

    it 'should trigger the save event', ->
      sinon.stub rs, 'writeJSON'
      rs.load().save()
      expect(emitStub.lastCall.args).to.deep.equal ['saved', 3]
