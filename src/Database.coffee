fs = require 'fs'
sysPath = require 'path'

mkdirp = require 'mkdirp'

utils = require './utils'
CoreObject = require './CoreObject'
MergedRecordStore = require './MergedRecordStore'
Model = require './Model'
ModelEx = require './ModelEx'

Class = null

###*
  The main class of the `local-json-db`, representing a database with one or more layers

  @since 0.0.2
  @class Database
  @extends CoreObject
  @constructor
  @example
    ```js
    var db = new Database();
    var record = db.createRecord({name: 'Huafu'});
    record.age = 31;
    db.updateRecord(record);
    console.log(db.find('user', record.id));
    // will output {id: 1, name: 'Huafu', age: 31}
    db.save();
    ```
###
class Database extends CoreObject
  ###*
    The base path
    @since 0.0.2
    @private
    @property _basePath
    @type String
    @default "./json.db"
  ###
  _basePath: null
  ###*
    Configuration options
    @since 0.0.2
    @private
    @property _config
    @type Object
    @default {deletedAtKey: "__deleted"}
  ###
  _config: null
  ###*
    Array of all layers (overlays) path
    @since 0.0.2
    @private
    @property _layers
    @type Array<String>
    @default [this._baseBath]
  ###
  _layers: null
  ###*
    Loaded models, indexed by their bare name
    @since 0.0.2
    @private
    @property _models
    @type Object<Model>
    @default null
  ###
  _models: null
  ###*
    The path to the database schema if any
    @since 0.0.7
    @private
    @property _schemaPath
    @type String
    @default null
  ###
  _schemaPath: null


  ###*
    Constructs a new instance of {{#crossLink "Database"}}{{/crossLink}}

    @since 0.0.2
    @method constructor
    @param {String} [basePath="./json.db"] The base path for the db files, hosting base JSON files of any added overlay
    @param {Object} [config={}] The configuration options
    @param {String|Array} [config.schemaPath=null] Path where the definition files for each model is
    @param {String} [config.createdAtKey] Name of the key to use as the `createdAt` flag for a record
    @param {String} [config.updatedAtKey] Name of the key to use as the `updatedAt` flag for a record
    @param {String} [config.deletedAtKey="__deleted"] Name of the key to use as the `deletedAt` flag for a record
  ###
  constructor: (basePath = './json.db', config = {}) ->
    @_basePath = sysPath.resolve basePath
    @_config = utils.defaults {}, config
    @_layers = [@_basePath]
    # keep to null so we know if we are loaded or not, in which case adding/removing layers would be impossible
    @_models = null
    if (path = config.schemaPath)
      if utils.isArray(path)
        path = sysPath.join(path...)
      @_schemaPath = sysPath.resolve @_basePath, path
    else
      @_schemaPath = null
    @lockProperties '_basePath', '_config', '_layers', '_schemaPath'


  ###*
    Finds whether this database has a schema or not

    @since 0.0.7
    @method hasSchema
    @return {Boolean} Returns `true` if the database has a schema, else `false`
  ###
  hasSchema: ->
    Boolean(@_schemaPath)


  ###*
    Add an overlay on top of all layers (the latest is the one used first, then come the others in order until the base)

    @since 0.0.2
    @method addOverlay
    @param {String} path  the path where to read/write JSON files of records, relative to the base path
    @chainable
  ###
  addOverlay: (path) ->
    @assertNotLoaded('cannot add overlay')
    if utils.isArray(path)
      path = sysPath.join(path...)
    path = sysPath.resolve @_basePath, path
    @assert path not in @_layers, "you cannot add twice the same path for 2 different overlays"
    @_layers.push path
    @


  ###*
    Creates a new record in the database

    @since 0.0.2
    @method createRecord
    @param {String} modelName name of the model
    @param {Object} record    attributes of the record to create
    @return {Object}          a copy of the newly created model with read-only `id`
  ###
  createRecord: (modelName, record) ->
    @modelFactory(modelName).create record


  ###*
    Updates a record with the given attributes

    @since 0.0.2
    @method updateModel
    @param {String} modelName   name of the model
    @param {String|Number} [id] id of the record to update, if not given it must be in `record`
    @param {Object} record      attributes of the record to update
    @return {Object}            a copy of the updated record
  ###
  updateRecord: (modelName, id, record) ->
    mdl = @modelFactory(modelName)
    mdl.update.apply mdl, [].slice.call(arguments, 1)


  ###*
    Deletes a record given its id

    @since 0.0.2
    @method deleteRecord
    @param {String} modelName name of the model
    @param {String|Number} id id of the record to delete
    @return {Object}          a copy of the old record which has been deleted
  ###
  deleteRecord: (modelName, id) ->
    @modelFactory(modelName).delete id


  ###*
    Finds a record by id

    @since 0.0.2
    @method find
    @param {String} modelName   name of the model
    @param {String|Number} id   id of the record to find
    @return {Object|undefined}  copy of the record if found, else `undefined`
  ###
  find: (modelName, id) ->
    @modelFactory(modelName).find id


  ###*
    Finds many record given a list of ids. If some records are not found, they'll just be filtered out
    of the resulting array

    @since 0.0.2
    @method findMany
    @param {String} modelName         name of the model
    @param {Array|String|Number} ids* id of each record to find, or one array with all record ids
    @return {Array<Object>}           array containing all found records
  ###
  findMany: (modelName, ids...) ->
    @modelFactory(modelName).findMany ids...


  ###*
    Finds records using a filter (either function or set of properties to match)

    @since 0.0.2
    @method findQuery
    @param {String} modelName       name of the model
    @param {Object|Function} filter attributes to match or a function used to filter records
    @param {Object} [thisArg]       will be used as the context to run the filter function
    @return {Array<Object>}         array with all records which matched
  ###
  findQuery: (modelName, filter, thisArg) ->
    @modelFactory(modelName).findQuery filter, thisArg


  ###*
    Finds all records in the database

    @since 0.0.2
    @method findAll
    @param {String} modelName name of the model
    @return {Array<Object>}   array containing all records of the given model
  ###
  findAll: (modelName) ->
    @modelFactory(modelName).findAll()


  ###*
    Counts all records of a given model

    @since 0.0.2
    @method count
    @param {String} modelName name of the model to count records
    @return {Number}          the total number of records
  ###
  count: (modelName) ->
    @modelFactory(modelName).count()


  ###*
    Saves in the top overlay's path the records that have been created/modified or deleted

    @since 0.0.2
    @method save
    @chainable
  ###
  save: ->
    if @isLoaded()
      models = []
      for own name, model of @_models
        @_saveModelStore name, model
        @emit 'model.store.saved', model
        models.push model
      @emit 'db.saved', model
    @


  ###*
    Whether the database has been loaded or not (in that case no overlay can be added)

    @since 0.0.2
    @method isLoaded
    @return {Boolean} returns `true` if the db is loaded, else `false`
  ###
  isLoaded: ->
    Boolean(@_models)


  ###*
    Loads the database (you don't need to call this method, it'll be automatically called when needed)

    @since 0.0.2
    @method load
    @param {Boolean} force  whether to force a reload in case it has already been loaded previously
    @chainable
  ###
  load: (force) ->
    if force or not @isLoaded()
      @unload()
      @_models = {}
    @


  ###*
    Unloads the database and all the records. **This does NOT save anything**

    @since 0.0.2
    @method unload
    @chainable
  ###
  unload: ->
    if @isLoaded()
      for own name, model of @_models
        model.destroy()
      @_models = null
    @


  ###*
    Destroy and free the db object

    @since 0.0.2
    @method destroy
  ###
  destroy: ->
    @unload()
    super


  ###*
    Get the {{#crossLink "Model"}}{{/crossLink}} instance given a model name

    @since 0.0.2
    @method modelFactory
    @param {String} modelName name of the model to get the instance
    @return {Model}           the model object
  ###
  modelFactory: (modelName) ->
    @load()
    name = @_modelName(modelName)
    unless (model = @_models[name])
      if (def = @_schemaPath)
        def = sysPath.join @_schemaPath, "#{ name }.json"
        @assert fs.existsSync(def), "unknown model #{ name }"
        def = require def
        model = new ModelEx(@, name, @_createModelStore(name), def)
      else
        model = new Model(@, name, @_createModelStore(name))
      @_models[name] = model
      @emit 'model.store.loaded', model
    model


  ###*
    Used to transform a model name into its store's JSON file name

    @since 0.0.2
    @method modelNameToFileName
    @param {String} modelName name of the model
    @return {String}          name of the file, sanitized and normalized
  ###
  modelNameToFileName: (modelName) ->
    Model.assertValidModelName modelName
    "#{ utils.kebabCase(utils.pluralize modelName) }.json"


  ###*
    Asserts that the DB hasn't been loaded yet, or throw an error

    @since 0.0.2
    @method assertNotLoaded
    @param {String} msg additional message to add in the error
    @chainable
  ###
  assertNotLoaded: (msg) ->
    @assert not @isLoaded(), "the database is already loaded#{if msg then ", #{msg}" else ''}"


  ###*
    Normalize a model name

    @since 0.0.2
    @method _modelName
    @private
    @param {String} name  name of the model to normalize
    @return {String}      normalized name
  ###
  _modelName: (name) ->
    Model._modelName name


  ###*
    Creates the store for a given model

    @since 0.0.2
    @private
    @method _createModelStore
    @param {String} name        name of the model
    @return {MergedRecordStore} the newly created store for the given model
  ###
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


  ###*
    Saves the store of a given model to disk

    @since 0.0.2
    @private
    @method _saveModelStore
    @param {String} name  name of the model
    @param {Model} model  model instance
    @return {String}      the full path of the file that has been saved
  ###
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


  ###*
    Name of the default attribute for a relationship to a given model

    @since 0.0.7
    @private
    @static
    @method _attributeForRelationship
    @param {String} toModel The destination model of the relationship
    @param {Boolean} [hasMany=false] Whether it's a hasMany relationship or not
    @return {String} Name of the attribute
  ###
  @_attributeForRelationship: (toModel, hasMany = no) ->
    "#{ toModel }Id#{ if hasMany then 's' else ''}"


  ###*
    Name of the default accessor for a relationship to a given model

    @since 0.0.7
    @private
    @static
    @method _accessorForRelationship
    @param {String} toModel The destination model of the relationship
    @param {Boolean} [hasMany=false] Whether it's a hasMany relationship or not
    @return {String} Name of the accessor
  ###
  @_accessorForRelationship: (toModel, hasMany = no) ->
    if hasMany
      utils.pluralize(toModel)
    else
      toModel


module.exports = Class = Database
