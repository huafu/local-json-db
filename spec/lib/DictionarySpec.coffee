{Dictionary} = lib

describe 'Dictionary', ->

  describe 'with default options', ->
    dict = null
    beforeEach ->
      dict = new Dictionary()
      dict.set 'a', 'blue'
      dict.set yes, 'yellow'


    it 'gets the entry for a key', ->
      expect(dict.entryForKey 'a').to.deep.equal {index: 0, key: 'a', value: 'blue'}
      expect(dict.entryForKey yes).to.deep.equal {index: 1, key: yes, value: 'yellow'}
      expect(dict.entryForKey null).to.deep.equal {index: -1}

    it 'gets the entry for a value', ->
      expect(dict.entryForValue 'blue').to.deep.equal {index: 0, key: 'a', value: 'blue'}
      expect(dict.entryForValue 'yellow').to.deep.equal {index: 1, key: yes, value: 'yellow'}
      expect(dict.entryForValue 'green').to.deep.equal {index: -1}

    it 'gets the entries for a value', ->
      dict.set 'b', 'blue'
      expect(dict.entriesForValue 'blue').to.deep.equal [
        {index: 0, key: 'a', value: 'blue'}
        {index: 2, key: 'b', value: 'blue'}
      ]
      expect(dict.entriesForValue 'brown').to.deep.equal []

    it 'finds the index of a key', ->
      expect(dict.indexOfKey 'a').to.equal 0
      expect(dict.indexOfKey true).to.equal 1
      expect(dict.indexOfKey 0).to.equal -1

    it 'finds the index of a value', ->
      expect(dict.indexOfValue 'blue').to.equal 0
      expect(dict.indexOfValue 'yellow').to.equal 1
      expect(dict.indexOfValue null).to.equal -1

    it 'counts all entries', ->
      expect(dict.count()).to.equal 2
      expect(dict.length).to.equal 2

    it 'clears all the entries', ->
      dict.clear()
      expect(dict.indexOfKey 'a').to.equal -1
      expect(dict.indexOfKey true).to.equal -1
      expect(dict.indexOfKey 0).to.equal -1
      expect(dict.indexOfValue 'blue').to.equal -1
      expect(dict.indexOfValue 'yellow').to.equal -1
      expect(dict.indexOfValue null).to.equal -1
      expect(dict.length).to.equal 0

    it 'gets an entry', ->
      expect(dict.get 'a').to.equal 'blue'
      expect(dict.get yes).to.equal 'yellow'
      expect(dict.get null).to.be.undefined

    it 'sets an entry', ->
      dict.set null, 'green'
      expect(dict.get null).to.equal 'green'
      dict.set 'a', 'a'
      expect(dict.get 'a').to.equal 'a'

    it 'imports an object', ->
      dict.import {o: 'o', u: 'u', a: 'a'}
      expect(dict.length).to.equal 4
      expect(dict.get 'a').to.equal 'a'
      expect(dict.get yes).to.equal 'yellow'
      expect(dict.get 'o').to.equal 'o'
      expect(dict.get 'u').to.equal 'u'

    it 'exports an object', ->
      expect(-> dict.export()).to.throw()

    it 'exports to key value pairs', ->
      expect(dict.toKeyValuePairs()).to.deep.equal [
        key: 'a', value: 'blue'
      ,
        key: yes, value: 'yellow'
      ]
      expect(dict.toKeyValuePairs(key: 'k', value: no, index: 'i')).to.deep.equal [
        k: 'a', i: 0
      ,
        k: yes, i: 1
      ]
      spy = sinon.spy()
      dict.toKeyValuePairs(null, spy)
      expect(spy.callCount).to.equal 2
      expect(spy.getCall(0).args).to.deep.equal [{key: 'a', value: 'blue'}, 0]
      expect(spy.getCall(1).args).to.deep.equal [{key: yes, value: 'yellow'}, 1]

    it 'gets all keys', ->
      expect(dict.keys()).to.deep.equal ['a', yes]

    it 'gets all values', ->
      expect(dict.values()).to.deep.equal ['blue', 'yellow']

    it 'finds whether a key exists', ->
      expect(dict.exists('a')).to.be.true
      expect(dict.exists(yes)).to.be.true
      expect(dict.exists(null)).to.be.false

    it 'finds whether a value exists', ->
      expect(dict.contains('blue')).to.be.true
      expect(dict.contains('yellow')).to.be.true
      expect(dict.contains('dummy')).to.be.false

    it 'unsets an entry', ->
      dict.unset('a')
      expect(dict.exists 'a').to.be.false
      expect(dict.length).to.equal 1
      dict.unset(yes)
      expect(dict.exists yes).to.be.false
      expect(dict.length).to.equal 0

    it 'emits entry set event', ->
      stub = sinon.stub dict, 'emit'
      dict.set 'o', 10
      expect(stub.calledOnce).to.be.true
      expect(stub.getCall(0).args).to.deep.equal [
        'entry.set'
        {index: 2, key: 'o', value: 10}
      ]
      stub.reset()
      dict.set no, undefined
      expect(stub.calledOnce).to.be.true
      expect(stub.getCall(0).args).to.deep.equal [
        'entry.set'
        {index: 3, key: no, value: undefined}
      ]

    it 'emits entry unset event', ->
      stub = sinon.stub dict, 'emit'
      dict.unset 'a'
      expect(stub.calledOnce).to.be.true
      expect(stub.getCall(0).args).to.deep.equal [
        'entry.unset'
        {index: 0, key: 'a', value: 'blue'}
      ]

    it 'maps entries'

    it 'collects entries'



  describe 'with stringified keys', ->
    dict = null
    beforeEach ->
      dict = new Dictionary({}, {stringifyKeys: yes})
      dict.set 'a', 'blue'
      dict.set yes, 'yellow'

    it 'gets the entry for a key', ->
      expect(dict.entryForKey 'a').to.deep.equal {index: 0, key: 'a', value: 'blue'}
      expect(dict.entryForKey yes).to.deep.equal {index: 1, key: 'true', value: 'yellow'}
      expect(dict.entryForKey null).to.deep.equal {index: -1}

    it 'gets the entry for a value', ->
      expect(dict.entryForValue 'blue').to.deep.equal {index: 0, key: 'a', value: 'blue'}
      expect(dict.entryForValue 'yellow').to.deep.equal {index: 1, key: 'true', value: 'yellow'}
      expect(dict.entryForValue 'green').to.deep.equal {index: -1}

    it 'gets the entries for a value', ->
      dict.set 'b', 'blue'
      expect(dict.entriesForValue 'blue').to.deep.equal [
        {index: 0, key: 'a', value: 'blue'}
        {index: 2, key: 'b', value: 'blue'}
      ]
      expect(dict.entriesForValue 'brown').to.deep.equal []

    it 'stringifies a key', ->
      expect(dict.stringifyKey('a')).to.equal 'a'
      expect(dict.stringifyKey(null)).to.equal 'null'
      expect(dict.stringifyKey(undefined)).to.equal 'undefined'
      expect(dict.stringifyKey(yes)).to.equal 'true'
      expect(dict.stringifyKey(false)).to.equal 'false'
      d = new Date()
      expect(dict.stringifyKey(d)).to.equal('' + d)

    it 'finds the index of a key', ->
      expect(dict.indexOfKey 'a').to.equal 0
      expect(dict.indexOfKey yes).to.equal 1
      expect(dict.indexOfKey 0).to.equal -1

    it 'finds the index of a value', ->
      expect(dict.indexOfValue 'blue').to.equal 0
      expect(dict.indexOfValue 'yellow').to.equal 1
      expect(dict.indexOfValue null).to.equal -1

    it 'counts all entries', ->
      expect(dict.count()).to.equal 2
      expect(dict.length).to.equal 2

    it 'clears all the entries', ->
      dict.clear()
      expect(dict.indexOfKey 'a').to.equal -1
      expect(dict.indexOfKey true).to.equal -1
      expect(dict.indexOfKey 0).to.equal -1
      expect(dict.indexOfValue 'blue').to.equal -1
      expect(dict.indexOfValue 'yellow').to.equal -1
      expect(dict.indexOfValue null).to.equal -1
      expect(dict.length).to.equal 0

    it 'gets an entry', ->
      expect(dict.get 'a').to.equal 'blue'
      expect(dict.get yes).to.equal 'yellow'
      expect(dict.get null).to.be.undefined

    it 'sets an entry', ->
      dict.set null, 'green'
      expect(dict.get null).to.equal 'green'
      dict.set 'a', 'a'
      expect(dict.get 'a').to.equal 'a'

    it 'imports an object', ->
      dict.import {o: 'o', u: 'u', a: 'a', 'true': 'brown'}
      expect(dict.length).to.equal 4
      expect(dict.get 'a').to.equal 'a'
      expect(dict.get yes).to.equal 'brown'
      expect(dict.get 'o').to.equal 'o'
      expect(dict.get 'u').to.equal 'u'

    it 'exports an object', ->
      expect(dict.export()).to.deep.equal {
        a:    'blue'
        true: 'yellow'
      }

    it 'exports to key value pairs', ->
      expect(dict.toKeyValuePairs()).to.deep.equal [
        key: 'a', value: 'blue'
      ,
        key: 'true', value: 'yellow'
      ]

    it 'gets all keys', ->
      expect(dict.keys()).to.deep.equal ['a', 'true']

    it 'gets all values', ->
      expect(dict.values()).to.deep.equal ['blue', 'yellow']

    it 'finds whether a key exists', ->
      expect(dict.exists('a')).to.be.true
      expect(dict.exists(yes)).to.be.true
      expect(dict.exists('true')).to.be.true
      expect(dict.exists(null)).to.be.false

    it 'finds whether a value exists', ->
      expect(dict.contains('blue')).to.be.true
      expect(dict.contains('yellow')).to.be.true
      expect(dict.contains('dummy')).to.be.false

    it 'unsets an entry', ->
      dict.unset('a')
      expect(dict.exists 'a').to.be.false
      expect(dict.length).to.equal 1
      dict.unset(yes)
      expect(dict.exists yes).to.be.false
      expect(dict.length).to.equal 0

    it 'emits entry set event', ->
      stub = sinon.stub dict, 'emit'
      dict.set 'o', 10
      expect(stub.calledOnce).to.be.true
      expect(stub.getCall(0).args).to.deep.equal [
        'entry.set'
        {index: 2, key: 'o', value: 10}
      ]
      stub.reset()
      dict.set no, undefined
      expect(stub.calledOnce).to.be.true
      expect(stub.getCall(0).args).to.deep.equal [
        'entry.set'
        {index: 3, key: 'false', value: undefined}
      ]

    it 'emits entry unset event', ->
      stub = sinon.stub dict, 'emit'
      dict.unset 'a'
      expect(stub.calledOnce).to.be.true
      expect(stub.getCall(0).args).to.deep.equal [
        'entry.unset'
        {index: 0, key: 'a', value: 'blue'}
      ]

  describe 'with `undefinedUnsets`', ->
    dict = null
    beforeEach ->
      dict = new Dictionary({}, {undefinedUnsets: yes})
      dict.set 'a', 'blue'
      dict.set yes, 'yellow'

    it 'removes an entry when setting to undefined', ->
      expect(dict.exists 'a').to.be.true
      dict.set 'a', undefined
      expect(dict.exists 'a').to.be.false

    it 'emits entry set event', ->
      stub = sinon.stub dict, 'emit'
      dict.set 'o', 10
      expect(stub.calledOnce).to.be.true
      expect(stub.getCall(0).args).to.deep.equal [
        'entry.set'
        {index: 2, key: 'o', value: 10}
      ]

    it 'emits entry unset event', ->
      stub = sinon.stub dict, 'emit'
      dict.set yes, undefined
      expect(stub.calledOnce).to.be.true
      expect(stub.getCall(0).args).to.deep.equal [
        'entry.unset'
        {index: 1, key: yes, value: 'yellow'}
      ]
      stub.reset()
      dict.unset 'a'
      expect(stub.calledOnce).to.be.true
      expect(stub.getCall(0).args).to.deep.equal [
        'entry.unset'
        {index: 0, key: 'a', value: 'blue'}
      ]


