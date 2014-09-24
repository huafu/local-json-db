fs = require 'fs'
sysPath = require 'path'

utils = require './utils'
CoreObject = require './CoreObject'
MergedRecordStore = require './MergedRecordStore'
Model = require './Model'

Class = null

class Database extends CoreObject
  _basePath: null
  _config: null
  _layers: null
  _models: null

  constructor: (basePath = './json.db', config = {}) ->
    @_basePath = sysPath.resolve basePath
    @_config = utils.defaults {}, config
    @_layers = [@_basePath]
    # keep to null so we know if we are loaded or not, in which case adding/removing layers would be impossible
    @_models = null
    @lockProperties '_basePath', '_config', '_layers'

  addOverlay: (path) ->
    @assertNotLoaded('cannot add overlay')
    if utils.isArray(path)
      path = sysPath.join(path...)
    path = sysPath.resolve @_basePath, path
    @assert path not in @_layers, "you cannot add twice the same path for 2 different overlays"
    @_layers.push path

  createRecord: (modelName, record) ->
    @modelFactory(modelName).create record

  updateRecord: (modelName, id, record) ->
    mdl = @modelFactory(modelName)
    mdl.update.apply mdl, [].slice.call(arguments, 1)

  deleteRecord: (modelName, id) ->
    @modelFactory(modelName).delete id

  find: (modelName, id) ->
    @modelFactory(modelName).find id

  findMany: (modelName, ids...) ->
    @modelFactory(modelName).findMany ids...

  findQuery: (modelName, filter, thisArg) ->
    @modelFactory(modelName).findQuery filter, thisArg

  findAll: (modelName) ->
    @modelFactory(modelName).findAll()

  count: (modelName) ->
    @modelFactory(modelName).count()

  isLoaded: ->
    Boolean(@_models)

  load: (force) ->
    if force or not @isLoaded()
      @unload()
      @_models = {}
    @

  unload: ->
    if @isLoaded()
      for own name, model of @_models
        model.destroy()
      @_models = null
    @

  destroy: ->
    @unload()
    super

  modelFactory: (modelName) ->
    @load()
    name = @_modelName(modelName)
    unless (model = @_models[name])
      @_models[name] = model = new Model(@, name, @_createModelStore(name))
      @emit 'model.store.loaded', model
    model

  save: ->
    if @isLoaded()
      models = []
      for own name, model of @_models
        @_saveModelStore model
        @emit 'model.store.saved', model
        models.push model
      @emit 'db.saved', model
    @

  modelNameToFileName: (modelName) ->
    "#{ utils.kebabCase(utils.pluralize modelName) }.json"

  assertNotLoaded: (msg) ->
    @assert not @isLoaded(), "the database is already loaded#{if msg then ", #{msg}" else ''}"


  _modelName: (name) ->
    Model._modelName name

  _createModelStore: (modelName) ->
    file = @modelNameToFileName @_modelName modelName
    stores = []
    for path in @_layers.reverse()
      path = sysPath.join path, file
      if fs.existsSync(path)
        data = fs.readFileSync path, encoding: 'utf8'
        data = JSON.parse data
        stores.push data
      else
        stores.push {config: {}, records: []}
    main = stores.pop()
    store = new MergedRecordStore(main.records, utils.defaults({}, @_config, main.config))
    for s in stores
      store.addLayer s.records, utils.defaults({}, main.config, s.config)
    store

  _saveModelStore: (model) ->
    file = @modelNameToFileName @_modelName model.name
    top = @_layers[@_layers.length - 1]
    path = sysPath.join top, file
    mkdirp.sync top
    fs.writeFileSync path, JSON.stringify(mode._store.layers(0).export())
    path





module.exports = Class = Database
