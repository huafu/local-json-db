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
      db = new Database(TEMP_DATA)

    afterEach ->
      db.destroy()

    it 'loads when trying to get a record', ->
      orig = db.load.bind(db)
      stub = sinon.stub db, 'load', orig
      db.find 'user', 1
      expect(stub.callCount).to.equal 1

