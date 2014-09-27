sysPath = require 'path'
fs = require 'fs'

ncp = require 'ncp'
mkdirp = require 'mkdirp'
rmdir = require 'rmdir'

{Database} = lib

SOURCE = sysPath.join __dirname, '..', 'data'
TEMP_DATA = sysPath.join __dirname, '..', '..', 'tmp', 'spec-data'
TEMP_DATA_WITH_MODELS = sysPath.join TEMP_DATA, 'with-models'

describe 'Database', ->
  db = null
  time = Date.now.bind(Date)
  nowStub = null
  now = null
  later = null
  jsonFile = (relPath...) ->
    file = sysPath.join(TEMP_DATA, relPath...) + '.json'
    if fs.existsSync(file)
      JSON.parse fs.readFileSync(file, encoding: 'utf8')
    else
      undefined

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

    it 'converts a model\'s name to a file name', ->
      expect(db.modelNameToFileName('user')).to.equal 'users.json'
      expect(db.modelNameToFileName('users')).to.equal 'users.json'
      expect(db.modelNameToFileName('Users')).to.equal 'users.json'
      expect(db.modelNameToFileName('UserPost')).to.equal 'user-posts.json'
      expect(-> db.modelNameToFileName(null)).to.throw()

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

    it 'finds all records', ->
      db.deleteRecord 'user', 1
      db.deleteRecord 'user', 2
      expect(db.findAll('user')).to.deep.equal [
        {id: 6, isClaimed: no, name: "John Doh", updatedAt: now}
      ]

    it 'counts all records', ->
      expect(db.count('user')).to.equal 3
      db.deleteRecord 'user', 2
      expect(db.count('user')).to.equal 2

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

    it 'saves all records', ->
      db.deleteRecord('user', 1)
      db.deleteRecord('post', 1)
      db.save()
      conf =
        createdAtKey: no
        updatedAtKey: 'updatedAt'
        deletedAtKey: '__deleted'
      expect(jsonFile 'users').to.deep.equal {
        config:  conf
        records: [
          {
            id:        '1'
            __deleted: now
          },
          {
            id:        2
            name:      "Pattiya Chamniphan"
            isClaimed: yes
            updatedAt: now
          },
          {
            id:        6
            name:      "John Doh"
            isClaimed: no
            updatedAt: now
          }
        ]
      }
      expect(jsonFile 'posts').to.deep.equal {
        config:  conf
        records: [
          {id: '1', __deleted: now}
          {
            id:        2,
            body:      "body of post 2"
            title:     "title of post 2"
            updatedAt: now
          }
        ]
      }


  describe 'with overlay', ->
    beforeEach ->
      db = new Database(TEMP_DATA, {updatedAtKey: 'updatedAt', deletedAtKey: 'deletedAt'})
      db.addOverlay(['alpha'])
      db.addOverlay('local')

    afterEach ->
      db.destroy()

    it 'finds a record and merges it', ->
      expect(db.find 'user', 1).to.be.undefined
      expect(db.find 'user', 2).to.deep.equal {
        id:        2
        isClaimed: no
        name:      "Pattiya Chamniphan"
        updatedAt: now
      }
      expect(db.find 'user', 6).to.be.undefined

    it 'saves only the difference', ->
      db.updateRecord 'user', {id: 2, name: null}
      db.deleteRecord 'user', 10
      db.createRecord 'user', {id: 1, name: 'Huafu'}
      db.save()
      conf = {createdAtKey: no, updatedAtKey: 'updatedAt', deletedAtKey: 'deletedAt'}
      expect(jsonFile 'local', 'users').to.deep.equal {
        config:  conf
        records: [
          {
            id:        1
            name:      "Huafu"
            updatedAt: now
          },
          {
            id:        "10"
            deletedAt: now
          },
          {
            id:        2
            isClaimed: false
            name:      null
            updatedAt: now
          },
          {
            id:        "6"
            deletedAt: Date.parse("2014-01-01T00:00:00.000Z")
          }
        ]
      }


  describe 'with predefined models', ->
    beforeEach ->
      db = new Database(TEMP_DATA_WITH_MODELS, {
        deletedAtKey: 'deletedAt'
        schemaPath: 'models'
      })
      db.addOverlay(['alpha'])
      db.addOverlay('local')

    afterEach ->
      db.destroy()

    it 'fails loading a unknown model', ->
      expect(-> db.modelFactory 'dummy').to.throw()

    it 'list all known attributes of a model', ->
      expect(db.modelFactory('user').knownAttributes()).to.deep.equal [
        'id', 'name', 'postIds', 'commentIds'
      ]
      expect(db.modelFactory('user').knownAttributes(no)).to.deep.equal [
        'id', 'name'
      ]
      expect(db.modelFactory('posts').knownAttributes()).to.deep.equal [
        'id', 'title', 'authorId', 'commentIds'
      ]
      expect(db.modelFactory('posts').knownAttributes(no)).to.deep.equal [
        'id', 'title'
      ]

    it 'throws an error when trying to set a unknown attribute on a fixed model', ->
      expect(-> db.createRecord 'user', {name: 'Huafu', age: 31}).to.throw()

    it 'allows setting unknown attributes on dynamic models', ->
      expect(-> db.createRecord 'post', {id: 1000, title: 'my post', published: yes}).to.not.throw()
      expect(db.find 'post', 1000).to.deep.equal {
        id: 1000
        title: 'my post'
        published: yes
        authorId: undefined
      }


    describe 'with `belongs to` relationship', ->
      user = null
      post = null
      beforeEach ->
        user = db.createRecord 'user', {name: 'Huafu'}
        post = db.createRecord 'post', {title: 'huafu post', author: user}
      afterEach ->
        user = post = null

      it 'reads a relationship property', ->
        expect(post).to.deep.equal {
          id: 1, title: 'huafu post', authorId: 1
        }
        expect(post.author).to.deep.equal {
          id: 1, name: 'Huafu'
        }
        expect(post.authorId).to.equal 1

        post = db.find 'post', 1
        expect(post).to.deep.equal {
          id: 1, title: 'huafu post', authorId: 1
        }
        expect(post.author).to.deep.equal {
          id: 1, name: 'Huafu'
        }
        expect(post.authorId).to.equal 1

      it 'updates a relationship property and saves it in the db', ->
        post.author = null
        expect(post.author).to.be.undefined
        expect(post.authorId).to.be.undefined
        post.author = user
        expect(post).to.deep.equal {
          id: 1, title: 'huafu post', authorId: 1
        }
        expect(post.author).to.deep.equal {
          id: 1, name: 'Huafu'
        }
        db.updateRecord post
        post = db.find 'post', 1
        expect(post).to.deep.equal {
          id: 1, title: 'huafu post', authorId: 1
        }
        expect(post.author).to.deep.equal {
          id: 1, name: 'Huafu'
        }
        expect(post.authorId).to.equal 1

      it.only 'updates related records\' volatile property', ->
        expect(user.postIds).to.deep.equal [1]
        expect(user.posts).to.deep.equal [
          {id: 1, title: 'huafu post', authorId: 1}
        ]



