sysPath = require 'path'
ncp = require 'ncp'
mkdirp = require 'mkdirp'
rmdir = require 'rmdir'

{Database} = lib

SOURCE = sysPath.join __dirname, '..', 'data'
TEMP_DATA = sysPath.join __dirname, 'tmp', 'spec-data'

describe 'Database', ->
  db = null
  time = Date.now.bind(Date)
  nowStub = null
  now = null
  later = null

  beforeEach (done) ->
    nowStub = sinon.stub Date, 'now', -> now
    now = time()
    later = now + 1000
    mkdirp.sync TEMP_DATA
    rmdir TEMP_DATA, (err) ->
      throw err if err
      ncp SOURCE, TEMP_DATA, (err) ->
        throw err if err
        done()

  afterEach (done) ->
    nowStub.restore()
    rmdir TEMP_DATA, (err) ->
      throw err if err
      done()



  describe 'without overlay', ->
    beforeEach ->
      db = new Database(TEMP_DATA, {updatedAtKey: 'updatedAt'})

    afterEach ->
      db.destroy()

    it 'converts a model\'s name to a file name'

    it 'loads when trying to get a record', ->
      orig = db.load.bind(db)
      stub = sinon.stub db, 'load', orig
      db.find 'user', 1
      expect(stub.callCount).to.equal 1

    it 'finds a record by id', ->
      user1 = {
        id:        1
        name:      'Huafu Gandon'
        joinedAt:  '2012-07-03T10:24:00.000Z'
        isClaimed: yes
        updatedAt: now
      }
      expect(db.find 'user', 1).to.deep.equal user1
      expect(db.find 'users', 1).to.deep.equal user1

    it 'finds many records by ids', ->
      user1 = {
        id:        1
        name:      'Huafu Gandon'
        joinedAt:  '2012-07-03T10:24:00.000Z'
        isClaimed: yes
        updatedAt: now
      }
      user2 = {
        id:        2
        name:      'Pattiya Chamniphan'
        isClaimed: yes
        updatedAt: now
      }
      expect(db.findMany 'users', [1, 2, 100]).to.deep.equal [
        user1, user2
      ]

    it 'finds many records with a filter', ->
      expect(db.findQuery 'user', {name: 'Pattiya Chamniphan'}).to.deep.equal [
        {id: 2, name: 'Pattiya Chamniphan', isClaimed: yes, updatedAt: now}
      ]
      expect(db.findQuery 'user', (r) -> r.id is 2).to.deep.equal [
        {id: 2, name: 'Pattiya Chamniphan', isClaimed: yes, updatedAt: now}
      ]

    it 'finds all records'

    it 'counts all records'

    it 'creates a record', ->
      expect(db.createRecord 'user', name: 'Luke').to.deep.equal {
        id: 7, name: 'Luke', updatedAt: now
      }

    it 'updates a record', ->
      expect(db.updateRecord 'user', 2, name: 'Mike').to.deep.equal {
        id: 2, name: 'Mike', isClaimed: yes, updatedAt: now
      }

    it 'deletes a record', ->
      expect(db.deleteRecord 'user', 1).to.deep.equal {
        id:        1
        name:      'Huafu Gandon'
        joinedAt:  '2012-07-03T10:24:00.000Z'
        isClaimed: yes
        __deleted: now
      }

    it 'saves all records'


  describe.skip 'with overlay', ->
