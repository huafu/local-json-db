{utils, CoreObject} = lib

class Level1 extends CoreObject
class Level2 extends Level1


describe 'CoreObject', ->

  describe 'className()', ->
    it 'should return the class name of a Class', ->
      expect(CoreObject.className()).to.equal 'CoreObject'
      expect(Level1.className()).to.equal 'Level1'
      expect(Level2.className()).to.equal 'Level2'

    it 'should return the class name of an object', ->
      expect((new CoreObject).className()).to.equal 'CoreObject'
      expect((new Level1).className()).to.equal 'Level1'
      expect((new Level2).className()).to.equal 'Level2'


  describe 'log()', ->
    stub = null
    beforeEach ->
      stub = sinon.stub utils, 'log'
    afterEach ->
      stub.restore()

    it 'should log with correct headers from a Class', ->
      stub.reset()
      CoreObject.log 'hello'
      expect(stub.calledWith '[CoreObject.log][debug]', 'hello').to.be.ok
      stub.reset()
      CoreObject.log 'warning', 'hello'
      expect(stub.calledWith '[CoreObject.log][warning]', 'hello').to.be.ok
      stub.reset()
      Level1.log 'hello'
      expect(stub.calledWith '[Level1.log][debug]', 'hello').to.be.ok
      stub.reset()
      Level1.log 'warning', 'hello'
      expect(stub.calledWith '[Level1.log][warning]', 'hello').to.be.ok
      stub.reset()
      Level2.log 'hello'
      expect(stub.calledWith '[Level2.log][debug]', 'hello').to.be.ok
      stub.reset()
      Level2.log 'warning', 'hello'
      expect(stub.calledWith '[Level2.log][warning]', 'hello').to.be.ok

    it 'should log with correct headers from an object', ->
      stub.reset()
      (new CoreObject).log 'hello'
      expect(stub.calledWith '[CoreObject#log][debug]', 'hello').to.be.ok
      stub.reset()
      (new CoreObject).log 'warning', 'hello'
      expect(stub.calledWith '[CoreObject#log][warning]', 'hello').to.be.ok
      stub.reset()
      (new Level1).log 'hello'
      expect(stub.calledWith '[Level1#log][debug]', 'hello').to.be.ok
      stub.reset()
      (new Level1).log 'warning', 'hello'
      expect(stub.calledWith '[Level1#log][warning]', 'hello').to.be.ok
      stub.reset()
      (new Level2).log 'hello'
      expect(stub.calledWith '[Level2#log][debug]', 'hello').to.be.ok
      stub.reset()
      (new Level2).log 'warning', 'hello'
      expect(stub.calledWith '[Level2#log][warning]', 'hello').to.be.ok


  describe 'assert()', ->
    it 'should do assertions from a Class', ->
      expect(-> CoreObject.assert(no, 'test')).to.throw '[CoreObject.assert] test'
      expect(-> CoreObject.assert(yes, 'test')).to.not.throw()
      expect(-> Level1.assert(no, 'test')).to.throw '[Level1.assert] test'
      expect(-> Level1.assert(yes, 'test')).to.not.throw()
      expect(-> Level2.assert(no, 'test')).to.throw '[Level2.assert] test'
      expect(-> Level2.assert(yes, 'test')).to.not.throw()

    it 'should do assertions from an object', ->
      expect(-> (new CoreObject).assert(no, 'test')).to.throw '[CoreObject#assert] test'
      expect(-> (new CoreObject).assert(yes, 'test')).to.not.throw()
      expect(-> (new Level1).assert(no, 'test')).to.throw '[Level1#assert] test'
      expect(-> (new Level1).assert(yes, 'test')).to.not.throw()
      expect(-> (new Level2).assert(no, 'test')).to.throw '[Level2#assert] test'
      expect(-> (new Level2).assert(yes, 'test')).to.not.throw()


  describe 'lockProperties()', ->
    it 'should lock properties on a Class', ->
      Level1.dummyProperty = 0
      expect(-> Level1.dummyProperty = 1).to.not.throw()
      Level1.lockProperties 'dummyProperty'
      expect(-> Level1.dummyProperty = 2).to.throw()
      Level2.dummyProperty = 0
      expect(-> Level2.dummyProperty = 1).to.not.throw()
      Level2.lockProperties 'dummyProperty'
      expect(-> Level2.dummyProperty = 2).to.throw()

    it 'should lock properties on an object', ->
      o = new CoreObject
      o.dummyProperty = 0
      expect(-> o.dummyProperty = 1).to.not.throw()
      o.lockProperties 'dummyProperty'
      expect(-> o.dummyProperty = 2).to.throw()
      o = new Level1
      o.dummyProperty = 0
      expect(-> o.dummyProperty = 1).to.not.throw()
      o.lockProperties 'dummyProperty'
      expect(-> o.dummyProperty = 2).to.throw()
      o = new Level2
      o.dummyProperty = 0
      expect(-> o.dummyProperty = 1).to.not.throw()
      o.lockProperties 'dummyProperty'
      expect(-> o.dummyProperty = 2).to.throw()

  describe 'uuid()', ->
    it 'should fail when no _uuid', ->
      expect(-> (new CoreObject).uuid()).to.throw()
      expect(-> (new Level1).uuid()).to.throw()
      expect(-> (new Level2).uuid()).to.throw()
    it 'should not fail when _uuid defined', ->
      o = new CoreObject
      o._uuid = 'uuid'
      expect(-> o.uuid()).to.not.throw()
      o = new Level1
      o._uuid = 'uuid'
      expect(-> o.uuid()).to.not.throw()
      o = new Level2
      o._uuid = 'uuid'
      expect(-> o.uuid()).to.not.throw()

  describe 'identify()', ->
    it 'should fail when no _uuid', ->
      expect(-> (new CoreObject).identify()).to.throw()
      expect(-> (new Level1).identify()).to.throw()
      expect(-> (new Level2).identify()).to.throw()
    it 'should return correct string when _uuid defined', ->
      o = new CoreObject
      o._uuid = 'uuid'
      expect(o.identify()).to.equal '[object CoreObject<uuid>]'
      o = new Level1
      o._uuid = 'uuid'
      expect(o.identify()).to.equal '[object Level1<uuid>]'
      o = new Level2
      o._uuid = 'uuid'
      expect(o.identify()).to.equal '[object Level2<uuid>]'

