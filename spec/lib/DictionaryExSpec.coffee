{DictionaryEx} = lib

describe 'DictionaryEx', ->
  dict = null
  time = Date.now.bind(Date)
  now = time()
  nowStub = null

  beforeEach ->
    nowStub = sinon.stub Date, 'now', -> now
    dict = new DictionaryEx()
    dict.set 'a', 'blue'
    dict.set yes, 'yellow'

  afterEach ->
    nowStub.restore()


  it 'unsets an entry', ->
    expect(dict.get 'a').to.equal 'blue'
    dict.unset 'a'
    expect(dict.get 'a').to.be.undefined

  it 'remembers deleted keys', ->
    expect(dict.deletedKeys()).to.deep.equal []
    expect(dict.deletedExists('a')).to.be.false
    dict.unset 'a'
    expect(dict.deletedKeys()).to.deep.equal ['a']
    expect(dict.deletedExists('a')).to.be.true
    dict.unset yes
    expect(dict.deletedKeys()).to.deep.equal ['a', yes]
    expect(dict.deletedExists(yes)).to.be.true

  it 'remembers creation date', ->
    expect(dict.createdAt 'a').to.equal now
    expect(dict.createdAt yes).to.equal now
    expect(dict.createdAt 'x').to.be.undefined
    oldNow = now
    now = time() + 1000
    dict.set 'o', {}
    expect(dict.createdAt 'o').to.equal now
    expect(dict.createdAt 'a').to.equal oldNow

  it 'remembers update date', ->
    expect(dict.updatedAt 'a').to.equal now
    expect(dict.updatedAt yes).to.equal now
    expect(dict.updatedAt 'x').to.be.undefined
    now = time() + 1000
    dict.set 'o', {}
    dict.set 'a', 'brown'
    expect(dict.updatedAt 'o').to.equal now
    expect(dict.updatedAt 'a').to.equal now

  it 'remembers deletion date', ->
    expect(dict.deletedAt 'a').to.be.undefined
    now = time() + 1000
    dict.unset 'a'
    expect(dict.deletedAt 'a').to.equal now
    expect(dict.exists 'a').to.be.false

  it 'updates creation date', ->
    now = time() + 1000
    dict.createdAt 'a', now
    expect(dict.createdAt 'a').to.equal now
    expect(-> dict.createdAt 'dummy', now).to.throw()

  it 'updates update date', ->
    now = time() + 1000
    dict.updatedAt 'a', now
    expect(dict.updatedAt 'a').to.equal now
    expect(-> dict.updatedAt 'dummy', now).to.throw()

  it 'updates deletion date', ->
    dict.unset('a')
    expect(dict.deletedAt 'a').to.equal now
    now = time() + 1000
    dict.deletedAt 'a', now
    expect(dict.deletedAt 'a').to.equal now
    expect(-> dict.deletedAt 'dummy', now).to.throw()
    expect(-> dict.deletedAt yes, now).to.not.throw()
    expect(dict.deletedAt yes).to.equal now
    expect(dict.exists yes).to.be.false

  it 'forgets deleted date after re-creation', ->
    now = time() + 1000
    dict.unset 'a'
    dict.set 'a', 'green'
    expect(dict.deletedAt 'a').to.be.undefined
    expect(dict.createdAt 'a').to.equal now
    expect(dict.updatedAt 'a').to.equal now

  it 'forgets a deleted key', ->
    dict.unset 'a'
    expect(dict.deletedExists 'a').to.be.true
    dict.deletedUnset 'a'
    expect(dict.deletedExists 'a').to.be.false

  it 'registers a unknown entry as deleted', ->
    dict.unset('a')
    expect(-> dict.deleted('a')).to.throw()
    expect(-> dict.deleted(yes)).to.throw()
    now = time() + 1000
    now2 = time() + 500
    dict.deleted 'dummy1'
    expect(dict.deletedAt 'dummy1').to.equal now
    dict.deleted 'dummy2', now2
    expect(dict.deletedAt 'dummy2').to.equal now2

  it 'exports to key value pairs', ->
    m = {createdAt: now, updatedAt: now}
    expect(dict.toKeyValuePairs()).to.deep.equal [
      key: 'a', value: 'blue', metadata: m
    ,
      key: yes, value: 'yellow', metadata: m
    ]
    expect(dict.toKeyValuePairs(key: 'k', value: no, index: 'i', metadata: no)).to.deep.equal [
      k: 'a', i: 0
    ,
      k: yes, i: 1
    ]
    spy = sinon.spy()
    dict.toKeyValuePairs(null, spy)
    expect(spy.callCount).to.equal 2
    expect(spy.getCall(0).args).to.deep.equal [{key: 'a', value: 'blue', metadata: m}, 0]
    expect(spy.getCall(1).args).to.deep.equal [{key: yes, value: 'yellow', metadata: m}, 1]

  it 'exports deleted entries', ->
    now = time() + 1000
    dict.unset 'a'
    expect(dict.deletedMetadata()).to.deep.equal [key: 'a', metadata: {deletedAt: now}]

  it 'counts all entries'

  it 'counts deleted entries'

  it 'clears all entries', ->
    dict.deleted('o')
    dict.clear no
    expect(dict.deletedExists 'o').to.be.true
    expect(dict.count()).to.equal 0
    dict.clear()
    expect(dict.deletedExists('o')).to.be.false

  it 'clears deleted entries'
