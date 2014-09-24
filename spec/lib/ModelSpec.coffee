{Model, Database, MergedRecordStore} = lib

describe 'Model', ->
  mdl = null
  rs = null
  time = Date.now.bind(Date)
  nowStub = null
  now = null
  later = null

  beforeEach ->
    nowStub = sinon.stub Date, 'now', -> now
    now = time()
    later = now + 1000
    rs = new MergedRecordStore([
      {id: 4, name: 'Bam', c: later, u: later}
      {id: 2, age: 35}
    ], {
      createdAtKey: 'c'
      updatedAtKey: 'u'
      deletedAtKey: 'd'
    })
    rs.addLayer [
      {id: 1, name: 'Huafu'}
      {id: 2, name: 'Mike', u: later}
      {id: 3, d: later}
    ]
    mdl = new Model(null, 'user', rs)

  afterEach ->
    nowStub.restore()


  it 'creates an instance', ->
    db = null
    expect(-> mdl = new Model(undefined, 'user', rs)).to.not.throw()
    expect(mdl.database).to.be.null
    expect(mdl.name).to.equal 'user'
    expect(-> mdl = new Model((db = new Database()), undefined, rs)).to.not.throw()
    expect(mdl.database).to.equal db
    expect(mdl.name).to.be.null
    expect(-> mdl = new Model(null, null, null)).to.not.throw()
    expect(mdl.database).to.be.null
    expect(mdl.name).to.be.null
    # now the wrong calls
    expect(-> mdl = new Model({}, null, null)).to.throw()
    expect(-> mdl = new Model(null, {}, null)).to.throw()
    expect(-> mdl = new Model(null, null, {})).to.throw()
    # model name conversions
    expect(new Model(null, 'users')).to.have.property 'name', 'user'
    expect(new Model(null, 'user')).to.have.property 'name', 'user'
    expect(new Model(null, 'User')).to.have.property 'name', 'user'
    expect(new Model(null, 'user-post')).to.have.property 'name', 'userPost'
    expect(new Model(null, 'user-posts')).to.have.property 'name', 'userPost'
    expect(new Model(null, 'userPost')).to.have.property 'name', 'userPost'
    expect(new Model(null, 'UserPost')).to.have.property 'name', 'userPost'
    expect(new Model(null, 'User_Post')).to.have.property 'name', 'userPost'

  it 'creates a record', ->
    expect(mdl.create name: 'Huafu', u: later).to.deep.equal {
      id: 5, name: 'Huafu', c: now, u: later
    }

  it 'updates a record', ->
    expect(mdl.update 1, name: 'Luke', c: later).to.deep.equal {
      id: 1, name: 'Luke', c: later, u: now
    }

  it 'deletes a record', ->
    expect(mdl.delete 1).to.deep.equal {
      id: 1, name: 'Huafu', d: now
    }

  it 'finds a record by ID', ->
    expect(mdl.find 2).to.deep.equal {
      id: 2, name: 'Mike', age: 35, c: now, u: now
    }
    expect(mdl.find 100).to.deep.equal undefined

  it 'finds many records by IDs', ->
    expect(mdl.findMany 1, 2, 100).to.deep.equal [
      {id: 1, name: 'Huafu', c: now, u: now}
      {id: 2, name: 'Mike', age: 35, c: now, u: now}
    ]
    expect(mdl.findMany [1, 2, 100]).to.deep.equal [
      {id: 1, name: 'Huafu', c: now, u: now}
      {id: 2, name: 'Mike', age: 35, c: now, u: now}
    ]

  it 'finds many records with a filter', ->
    expect(mdl.findQuery {name: 'Huafu'}).to.deep.equal [
      {id: 1, name: 'Huafu', c: now, u: now}
    ]
    expect(mdl.findQuery (r) -> r.id > 3).to.deep.equal [
      {id: 4, name: 'Bam', c: later, u: later}
    ]

  it 'finds all records', ->
    expect(mdl.findAll()).to.deep.equal [
      {id: 1, name: 'Huafu', c: now, u: now}
      {id: 2, name: 'Mike', age: 35, c: now, u: now}
      {id: 4, name: 'Bam', c: later, u: later}
    ]

  it 'counts records', ->
    expect(mdl.count()).to.equal 3

