RecordStore = require '../../lib/RecordStore'
sysPath = require 'path'

describe 'RecordStore', ->
  newRecordStore = (path, options) ->
    new RecordStore sysPath.join(__dirname, '..', 'data', "#{ path }.json"), options
  rs = null

  beforeEach ->
    rs = newRecordStore 'user'

  describe 'writable', ->
    it 'should read JSON', ->
      expect(rs.readJSON()).to.deep.equal [
        {
          id:        1,
          name:      "Huafu Gandon",
          joinedAt:  "2012-07-03T10:24:00.000Z",
          isClaimed: true
        },
        {
          id:        2,
          name:      "Pattiya Chamniphan",
          isClaimed: true
        },
        {
          id:        6,
          name:      "John Doh",
          isClaimed: false
        }
      ]

    it 'should not load invalid data', ->
      rs = null
      expect(-> rs = newRecordStore('invalid')).to.not.throw()
      expect(-> rs.load()).to.throw()

    it 'should load valid data', ->
      expect(-> rs.load()).to.not.throw()
      rs = newRecordStore('post')
      expect(-> rs.load()).to.not.throw()

    it 'should count records', ->
      expect(rs.count()).to.equal 3
      expect(newRecordStore('post').count()).to.equal 2

    it 'should know the last free auto-id', ->
      expect(rs.load()._lastId).to.equal 6
      expect(newRecordStore('post').load()._lastId).to.equal 2

    it 'should find record by id', ->
      expect(rs.find(1)).to.deep.equal {
        id:        1,
        name:      "Huafu Gandon",
        joinedAt:  "2012-07-03T10:24:00.000Z",
        isClaimed: yes
      }
      expect(rs.find(2)).to.deep.equal {
        id:        2,
        name:      "Pattiya Chamniphan",
        isClaimed: yes
      }
      expect(rs.find(6)).to.deep.equal {
        id:        6,
        name:      "John Doh",
        isClaimed: no
      }

    it 'should not find unknown record', ->
      expect(rs.find 10).to.be.undefined
      expect(rs.find 20).to.be.undefined

    it 'should lock the value of a record id', ->
      r = rs.find(1)
      expect(-> r.id = 10).to.throw()
      expect(-> r.name = "Some Name").to.not.throw()

    it 'should return always the same object with `find`', ->
      r1 = rs.find(1)
      r2 = rs.find(1)
      expect(r1).to.equal r2

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
      expect(rs.find(7)).to.deep.equal record1
      expect(rs.find(12)).to.deep.equal record2
      expect(rs.find(13)).to.deep.equal record3

    it 'should not create record with existing or invalid id', ->
      expect(-> rs.createRecord id: 0).to.throw()
      expect(-> rs.createRecord id: 6).to.throw()

    it 'should delete record by id', ->
      rs.deleteRecord(1)
      expect(rs.find 1).to.be.undefined
      rs.deleteRecord(6)
      expect(rs.find 6).to.be.undefined

    it 'should not delete undefined record', ->
      expect(-> rs.deleteRecord 10).to.throw()
      expect(-> rs.deleteRecord 10, no).to.not.throw()

    it 'should write changes when saving', ->
      orig = rs.readJSON()
      stub = sinon.stub rs, 'writeJSON'
      # change some stuff
      rs.find(1).name = "Julian"
      orig[0].name = "Julian"
      rs.deleteRecord(6)
      orig.pop()
      rs.createRecord name: "Bam"
      orig.push id: 7, name: "Bam"
      rs.save()
      expect(stub.calledOnce).to.be.true
      expect(stub.getCall(0).args[0]).to.deep.equal orig


  describe 'read only', ->
    rs = null
    beforeEach ->
      rs = newRecordStore('user', readOnly: yes)

    it.skip 'should fail when trying to update a record', ->
      expect(-> rs.find(1).name = "Lilian").to.throw()

    it 'should not retain changes', ->
      rs.find(1).name = "Lilian"
      expect(rs.find(1).name).to.equal "Huafu Gandon"

    it 'should fail when trying to create a record', ->
      expect(-> rs.createRecord name: "Tor").to.throw()

    it 'should fail when trying to delete a record', ->
      expect(-> rs.deleteRecord 1).to.throw()

    it 'should fail when trying to save', ->
      expect(-> rs.save()).to.throw()
