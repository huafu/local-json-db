fs = require 'fs'
sysPath = require 'path'

mkdirp = require 'mkdirp'

utils = require './utils'
CoreObject = require './CoreObject'
MergedRecordStore = require './MergedRecordStore'
Model = require './Model'

Class = null

# The main class of the `local-json-db`, representing a database with one or more layers
#
# @since 0.0.2
# @example
#   db = new Database()
#   record = db.createRecord {name: 'Huafu'}
#   record.age = 31
#   db.updateRecord record
#   db.save()
class Database extends CoreObject
  _basePath: null
  _config: null
  _layers: null
  _models: null

  # Constructs a new instance of {Database}
  #
  # @since 0.0.2
  # @param {String} basePath              the base path for the db files, hosting base JSON files of any added overlay
  # @option config {String} createdAtKey  name of the key to use as the `createdAt` flag for a record
  # @option config {String} updatedAtKey  name of the key to use as the `updatedAt` flag for a record
  # @option config {String} deletedAtKey  name of the key to use as the `deletedAt` flag for a record (default `__deleted`)
  constructor: (basePath = './json.db', config = {}) ->
    @_basePath = sysPath.resolve basePath
    @_config = utils.defaults {}, config
    @_layers = [@_basePath]
    # keep to null so we know if we are loaded or not, in which case adding/removing layers would be impossible
    @_models = null
    @lockProperties '_basePath', '_config', '_layers'


  # Add an overlay on top of all layers (the latest is the one used first, then come the others in order until the base)
  #
  # @since 0.0.2
  # @param {String} path  the path where to read/write JSON files of records, relative to the base path
  # @return {Database}    this object for chaining
  addOverlay: (path) ->
    @assertNotLoaded('cannot add overlay')
    if utils.isArray(path)
      path = sysPath.join(path...)
    path = sysPath.resolve @_basePath, path
    @assert path not in @_layers, "you cannot add twice the same path for 2 different overlays"
    @_layers.push path
    @


  # Creates a new record in the database
  #
  # @since 0.0.2
  # @param {String} modelName name of the model
  # @param {Object} record    attributes of the record to create
  # @return {Object}          a copy of the newly created model with read-only `id`
  createRecord: (modelName, record) ->
    @modelFactory(modelName).create record


  # Updates a record with the given attributes
  #
  # @overload updateModel(modelName, id, record)
  #   @since 0.0.2
  #   @param {String} modelName   name of the model
  #   @param {String, Number} id  id of the record to update
  #   @param {Object} record      attributes of the record to update
  #   @return {Object}            a copy of the updated record
  #
  # @overload updateModel(modelName, record)
  #   @since 0.0.2
  #   @param {String} modelName   name of the model
  #   @param {Object} record      attributes of the record to update (including its id)
  #   @return {Object}            a copy of the updated record
  updateRecord: (modelName, id, record) ->
    mdl = @modelFactory(modelName)
    mdl.update.apply mdl, [].slice.call(arguments, 1)


  # Deletes a record given its id
  #
  # @since 0.0.2
  # @param {String} modelName name of the model
  # @return {Object}          a copy of the old record which has been deleted
  deleteRecord: (modelName, id) ->
    @modelFactory(modelName).delete id


  # Finds a record by id
  #
  # @since 0.0.2
  # @param {String} modelName   name of the model
  # @param {String, Number} id  id of the record to find
  # @return {Object, undefined} copy of the record if found, else `undefined`
  find: (modelName, id) ->
    @modelFactory(modelName).find id


  # Finds many record given a list of ids. If some records are not found, they'll just be filtered out
  # of the resulting array
  #
  # @overload findMany(modelName, ids...)
  #   @since 0.0.2
  #   @param {String} modelName       name of the model
  #   @param {String, Number} ids...  id of each record to find
  #   @return {Array<Object>}         array containing all found records
  #
  # @overload findMany(modelName, ids)
  #   @since 0.0.2
  #   @param {String} modelName           name of the model
  #   @param {Array<String, Number>} ids  array of id for each record to find
  #   @return {Array<Object>}             array containing all found records
  findMany: (modelName, ids...) ->
    @modelFactory(modelName).findMany ids...


  # Finds records using a filter (either function or set of properties to match)
  #
  # @overlay findQuery(modelName, filter)
  #   @since 0.0.2
  #   @param {String} modelName name of the model
  #   @param {Object} filter    attributes to match
  #   @return {Array<Object>}   array with all records which matched
  #
  # @overlay findQuery(modelName, filter, thisArg)
  #   @since 0.0.2
  #   @param {String} modelName name of the model
  #   @param {Function} filter  function used to filter records, each record is given as the first parameter
  #   @param {Object} thisArg   optional, will be used as the context to run the filter function
  #   @return {Array<Object>}   array with all records which matched
  findQuery: (modelName, filter, thisArg) ->
    @modelFactory(modelName).findQuery filter, thisArg


  # Finds all records in the database
  #
  # @since 0.0.2
  # @param {String} modelName name of the model
  # @return {Array<Object>}   array containing all records of the given model
  findAll: (modelName) ->
    @modelFactory(modelName).findAll()


  # Counts all records of a given model
  #
  # @since 0.0.2
  # @param {String} modelName name of the model to count records
  # @return {Number}          the total number of records
  count: (modelName) ->
    @modelFactory(modelName).count()


  # Saves in the top overlay's path the records that have been created/modified or deleted
  #
  # @since 0.0.2
  # @return {Database} this object for chaining
  save: ->
    if @isLoaded()
      models = []
      for own name, model of @_models
        @_saveModelStore name, model
        @emit 'model.store.saved', model
        models.push model
      @emit 'db.saved', model
    @


  # Whether the database has been loaded or not (in that case no overlay can be added)
  #
  # @since 0.0.2
  # @return {Boolean} returns `true` if the db is loaded, else `false`
  isLoaded: ->
    Boolean(@_models)


  # Loads the database
  #
  # @since 0.0.2
  # @param {Boolean} force  whether to force a reload in case it has already been loaded previously
  # @return {Database}      this object to do chained calls
  load: (force) ->
    if force or not @isLoaded()
      @unload()
      @_models = {}
    @


  # Unloads the database and all the records. **This does NOT save anything**
  #
  # @since 0.0.2
  # @return {Database} this object to do chained calls
  unload: ->
    if @isLoaded()
      for own name, model of @_models
        model.destroy()
      @_models = null
    @


  # @see {CoreObject#destroy}
  destroy: ->
    @unload()
    super


  # Get the {Model} instance given a model name
  #
  # @since 0.0.2
  # @param {String} modelName name of the model to get the instance
  # @return {Model}           the model object
  modelFactory: (modelName) ->
    @load()
    name = @_modelName(modelName)
    unless (model = @_models[name])
      @_models[name] = model = new Model(@, name, @_createModelStore(name))
      @emit 'model.store.loaded', model
    model


  # Used to transform a model name into its store's JSON file name
  #
  # @since 0.0.2
  # @param {String} modelName name of the model
  # @return {String}          name of the file, sanitized and normalized
  modelNameToFileName: (modelName) ->
    Model.assertValidModelName modelName
    "#{ utils.kebabCase(utils.pluralize modelName) }.json"


  # Asserts that the DB hasn't been loaded yet, or throw an error
  #
  # @since 0.0.2
  # @param {String} msg additional message to add in the error
  # @return {Database}  this object for chaining
  assertNotLoaded: (msg) ->
    @assert not @isLoaded(), "the database is already loaded#{if msg then ", #{msg}" else ''}"


  # @private
  # @since 0.0.2
  _modelName: (name) ->
    Model._modelName name


  # @private
  # @since 0.0.2
  _createModelStore: (modelName) ->
    file = @modelNameToFileName @_modelName modelName
    stores = []
    for path in @_layers.slice().reverse()
      path = sysPath.join path, file
      if fs.existsSync(path)
        data = fs.readFileSync path, encoding: 'utf8'
        data = JSON.parse data
        stores.push data
      else
        stores.push {config: {}, records: []}
    main = stores.shift()
    store = new MergedRecordStore(main.records, utils.defaults({}, @_config, main.config))
    for s in stores
      store.addLayer s.records, utils.defaults({}, main.config, s.config)
    store


  # @private
  # @since 0.0.2
  _saveModelStore: (name, model) ->
    file = @modelNameToFileName @_modelName name
    top = @_layers[@_layers.length - 1]
    path = sysPath.join top, file
    store = model._store
    if store.countRecords(yes) is 0
      fs.unlinkSync(path) if fs.existsSync(path)
    else
      mkdirp.sync top
      fs.writeFileSync path, JSON.stringify(store.export())
    path


module.exports = Class = Database
