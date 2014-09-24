# stuff we need for testing
sysPath = require 'path'
fs = require 'fs'

ncp = require 'ncp'
mkdirp = require 'mkdirp'
rmdir = require 'rmdir'

TEMP_DATA = sysPath.join __dirname, '..', '..', 'tmp', 'spec-ex-data'

jsonFile = (relPath...) ->
  file = sysPath.join(TEMP_DATA, relPath...) + '.json'
  if fs.existsSync(file)
    JSON.parse fs.readFileSync(file, encoding: 'utf8')
  else
    undefined

allJson = (overlay) ->
  res = {}
  for m in ['users', 'posts', 'comments']
    p = [m]
    p.unshift(overlay) if overlay
    res[m] = jsonFile p...


describe 'simple example use case', ->
  # some other stuff for testing only ===========
  time = Date.now.bind(Date)
  nowStub = null
  now = time()
  before (done) ->
    nowStub = sinon.stub Date, 'now', -> now
    mkdirp.sync TEMP_DATA
    rmdir TEMP_DATA, (err) ->
      throw err if err
      done()
  after (done) ->
    nowStub.restore()
    rmdir TEMP_DATA, (err) ->
      throw err if err
      done()
  afterEach ->
    db?.destroy()
    db = null
  # =============================================

  # define our variables ================
  {Database} = require '../..'
  db = null
  user1 = null
  user2 = null
  post1 = null
  comment1 = null
  comment2 = null
  comment3 = null
  coreJson = null
  testJson = null
  localJson = null


  describe 'setup our core records', ->
    before ->
      db = new Database(TEMP_DATA)
    after ->
      db.save()
      coreJson = allJson()


    it 'creates the user #1', ->
      user1 = db.createRecord 'user', name: 'Huafu'
      expect(user1).to.deep.equal {id: 1, name: 'Huafu'}


    it 'creates the user #2', ->
      user2 = db.createRecord 'user', name: 'Mike'
      expect(user2).to.deep.equal {id: 2, name: 'Mike'}


  describe 'setup our testing overlay records', ->
    before ->
      db = new Database(TEMP_DATA)
      db.addOverlay 'test'
    after ->
      db.save()
      testJson = allJson('test')


    it 'updates the user #2', ->
      user2 = db.updateRecord 'user', user2.id, name: 'Luke'
      expect(user2).to.deep.equal {id: 2, name: 'Luke'}


    it 'creates the post #1', ->
      post1 = db.createRecord 'post', {title: 'post 1', authorId: user1.id}
      expect(post1).to.deep.equal {id: 1, title: 'post 1', authorId: user1.id}


    it 'creates the comment #1', ->
      comment1 = db.createRecord 'comment', {
        postId: post1.id
        userId: user2.id
        text:   'comment from user 2'
      }
      expect(comment1).to.deep.equal {
        id:     1
        postId: post1.id
        userId: user2.id
        text:   'comment from user 2'
      }


  describe 'use our previously setup records with a local overlay', ->
    before ->
      db = new Database(TEMP_DATA)
      db.addOverlay 'test'
      db.addOverlay 'local'
    after ->
      db.save()
      localJson = allJson('local')


    it 'finds our previously saved records', ->
      expect(db.find 'user', 1).to.deep.equal {id: 1, name: 'Huafu'}
      expect(db.find 'user', 2).to.deep.equal {id: 2, name: 'Luke'}

      expect(db.find 'post', 1).to.deep.equal {id: 1, title: 'post 1', authorId: user1.id}
      expect(db.findQuery 'post', authorId: user1.id).to.deep.equal [
        {id: 1, title: 'post 1', authorId: user1.id}
      ]

      expect(db.find 'comment', 1).to.deep.equal {
        id:     1
        postId: post1.id
        userId: user2.id
        text:   'comment from user 2'
      }
      expect(db.findQuery 'comment', postId: post1.id).to.deep.equal [
        {id: 1, postId: post1.id, userId: user2.id, text: 'comment from user 2'}
      ]


    it 'creates comment #2 and #3', ->
      comment2 = db.createRecord 'comment', {
        postId: post1.id
        userId: user1.id
        text:   'comment from user 1'
      }
      expect(comment2).to.deep.equal {
        id:     2
        postId: post1.id
        userId: user1.id
        text:   'comment from user 1'
      }
      comment3 = db.createRecord 'comment', {
        postId: post1.id
        userId: user2.id
        text:   'other comment from user 2'
      }
      expect(comment3).to.deep.equal {
        id:     3
        postId: post1.id
        userId: user2.id
        text:   'other comment from user 2'
      }


    it 'finds all out records', ->
      expect(db.findQuery 'comment', userId: user2.id).to.deep.equal [
        {id: comment1.id, postId: post1.id, userId: user2.id, text: 'comment from user 2'}
        {id: comment3.id, postId: post1.id, userId: user2.id, text: 'other comment from user 2'}
      ]
      expect(db.findQuery 'comment', postId: post1.id).to.deep.equal [
        {id: comment1.id, postId: post1.id, userId: user2.id, text: 'comment from user 2'}
        {id: comment2.id, postId: post1.id, userId: user1.id, text: 'comment from user 1'}
        {id: comment3.id, postId: post1.id, userId: user2.id, text: 'other comment from user 2'}
      ]


    it 'deletes comment #1 and update post #1', ->
      db.deleteRecord 'comment', comment1.id
      db.updateRecord 'post', post1.id, title: 'hello!'


  describe 'check that only the overlay is modified', ->
    dbCore = null
    dbTest = null
    dbLocal = null
    before ->
      dbCore = new Database(TEMP_DATA)
      dbTest = new Database(TEMP_DATA)
      dbTest.addOverlay('test')
      dbLocal = new Database(TEMP_DATA)
      dbLocal.addOverlay('test')
      dbLocal.addOverlay('local')
    after ->
      dbCore.destroy()
      dbCore = null
      dbTest.destroy()
      dbTest = null
      dbLocal.destroy()
      dbLocal = null

    it 'did not change the core and test layers', ->
      expect(allJson()).to.deep.equal coreJson
      expect(allJson('test')).to.deep.equal testJson

    it 'kept different version of user #2', ->
      expect(dbCore.find 'user', 2).to.deep.equal {id: 2, name: 'Mike'}
      expect(dbTest.find 'user', 2).to.deep.equal {id: 2, name: 'Luke'}
      expect(dbLocal.find 'user', 2).to.deep.equal {id: 2, name: 'Luke'}

    it 'kept different version of post #1', ->
      expect(dbCore.find 'post', 1).to.be.undefined
      expect(dbTest.find 'post', 1).to.deep.equal {id: 1, title: 'post 1', authorId: user1.id}
      expect(dbLocal.find 'post', 1).to.deep.equal {id: 1, title: 'hello!', authorId: user1.id}

    it 'kept different version of comment #1', ->
      expect(dbCore.find 'comment', 1).to.be.undefined
      expect(dbTest.find 'comment', 1).to.deep.equal {
        id: 1, postId: post1.id, userId: user2.id, text: 'comment from user 2'
      }
      expect(dbLocal.find 'comment', 1).to.be.undefined





