{RecordStore} = lib

describe.skip 'RecordStore', ->
  rs = null
  time = Date.now.bind(Date)
  now = time()
  nowStub = null

  beforeEach = ->
    nowStub = sinon.stub Date, 'now', -> now
    rs = new RecordStore()

  afterEach = ->
    nowStub.restore()

  it 'creates a record', ->
    rec = rs.createRecord name: 'Mike'
    expect(rec).to.deep.equal id: 1, name: 'Mike'
