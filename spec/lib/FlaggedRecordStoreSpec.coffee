sysPath = require 'path'
FlaggedRecordStore = require '../../lib/FlaggedRecordStore'

newRecordStore = (path, options) ->
  new FlaggedRecordStore jsonPath(path), options

describe 'FlaggedRecordStore', ->
  rs = null
  beforeEach ->
    rs = newRecordStore('user')


  it 'should count records', ->
    expect(rs.countRecords()).to.equal 3
    rs.deleteRecord(2)
    expect(rs.countRecords()).to.equal 2

  it 'should virtually delete a record', ->
    expect(rs.readRecord(2)).to.be.ok
    rs.deleteRecord(2)
    expect(rs.countRecords(no)).to.equal 3
    expect(rs.readRecord(2)).to.be.null
    expect(rs.readRecord(10)).to.be.undefined
    expect(rs.readRecord(2, no)).to.deep.equal id: 2, __deleted: yes

  it 'should not update virtually deleted record', ->
    expect(-> rs.updateRecord(2, name: 'John')).to.not.throw()
    rs.deleteRecord(2)
    expect(-> rs.updateRecord(2, name: 'Mike')).to.throw()

  it 'should not re-delete virtually deleted record', ->
    rs.deleteRecord(2)
    expect(-> rs.deleteRecord(2)).to.throw()

  it 'should create previously deleted record', ->
    expect(-> rs.createRecord(id: 2, name: 'Mike')).to.throw()
    rs.deleteRecord(2)
    expect(-> rs.createRecord(id:2, name: 'Mike')).to.not.throw()
    expect(rs.readRecord(2)).to.deep.equal {id:2, name: 'Mike'}

