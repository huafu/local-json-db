utils = require '../../lib/utils'

describe 'utils', ->

  describe 'copy', ->
    testOne = (value, isVector) ->
      orig = value
      copy = utils.copy orig
      if isVector
        expect(orig).to.equal copy
        orig = {}
        expect(copy).to.not.equal orig
      else
        expect(orig).to.not.equal copy
        expect(orig).to.deep.equal copy

    it 'should clone scalar data', ->
      testOne null, yes
      testOne undefined, yes
      testOne no, yes
      testOne yes, yes
      testOne 'hello', yes
      testOne 10, yes
      testOne Infinity, yes

    it 'should clone non scalar data', ->
      testOne NaN
      testOne new String('hello')
      testOne new Number(10)
      testOne {id: 10}
      testOne new Date()

  describe 'throw', ->
    expect(-> utils.throw 'test').to.throw('test')
    expect(-> utils.throw TypeError, 'test').to.throw(TypeError)

  describe 'lock', ->
    it 'should lock property of an object', ->
      o = {id: 10}
      expect(-> o.id = 20).to.not.throw()
      utils.lock o, 'id'
      expect(-> o.id = 30).to.throw()
      expect(o.id).to.equal 20
      expect('id' in Object.keys(o)).to.be.true
      o = {id: 10}
      utils.lock o, 'id', no
      expect(-> o.id = 30).to.throw()
      expect(o.id).to.equal 10
      expect('id' in Object.keys(o)).to.be.false

