local-json-db [![Build Status](https://travis-ci.org/huafu/local-json-db.svg?branch=master)](https://travis-ci.org/huafu/local-json-db) [![Coverage Status](https://coveralls.io/repos/huafu/local-json-db/badge.png?branch=master)](https://coveralls.io/r/huafu/local-json-db?branch=master) [![NPM version](https://badge.fury.io/js/local-json-db.png)](http://badge.fury.io/js/local-json-db)
=============

Local JSON DB is exclusively designed for local environments and testing purpose. Globally, it's a
memory database using overlays and that can persist to JSON files.

Let's say you want a local environment for your HTML5 application (could be any other type of
application), but without the pain and overload of a VM or any other heavy install for a local API.
You could have for example an extremely simple `expresjs` app delivering content hard-coded in that
fake API, or source from some JSON.

But then you need your developers to be able to save locally some different records than the ones
shared by the fake API, while still using the constantly updated core records pushed to the VCS.
You also want to be able to have some other specific data to run unit tests of your client for example.

**Well, `local-json-db` is here for that!**

## Usage

First of all, install it as a dependency of your project. In the root path of your project, run this:

```
npm install --save-dev local-json-db
```

Then, in your CoffeeScript file:

```coffee
ljdb = require 'local-json-db'
db = new ljdb.Database()
```

or in javascript:

```js
var ljdb = require('local-json-db');
var db = new ljdb.Database();
```


## Example

Here is the directory structure of your app:
```
app/
  # all the client files, in our case HTML5 application for example
mock-api/
  lib/
    # the simple API using `local-json-db` to provide read-only but also rw mocks
  data/
    # the core json files containing the records shared in all overlays
    users.json
    posts.json
    local/
      # ignored by the VCS, containing the overlays for local use only,
      # as for each developer for example
```

Assuming `PROJECT_ROOT` is a reference to the root directory of our project, when running the micro
fake API delivering mocks:

```js
var db = new Database(PROJECT_ROOT + 'mock-api/data');
db.addOverlay('local'); // relative to the path given in new Database()
```

You'll then have a database reading records from `mock-api/data` JSON files and merging them with
the ones in `mock-api/data/local`. When saving the DB (with `db.save()`), only the difference
will be saved in `mock-api/data/local` JSON files. Nothing will be changed in the JSON files
located in `mock-api/data`, not even the deleted records.

Now you want to update the core files to share with others the addition of records or such. It's
as easy as commenting the second line in the script above. Without overlay, the changes will be
saved directly in the root directory given as parameter of `new Database()`

Also you might want to keep the records volatile and not saving the database after a run. Well,
again as simple as commenting out the `db.save()` you'd usually place in the shutdown of your app.
    
---

You might use this for unit testing as well, having multiple set of data but with a core data being
constant, without duplicating it over and over in all unit tests.

You can add as many overlay as you want, just keep in mind tha `db.save()` will save the diff (ie the
created, changed or deleted) records in the last overlay you added before using the database object.


## Database API:

Any `modelName` will be dasherized and pluralized to get the file name used as a record store for
that model. Also whatever you are going to use in the following methods as model name will always
meet the same base model name (for example `userPost`, `userPosts`, `user_post`, ... will all point
to the same model, and so the same store in each overlay)

An important thing to note is that updating a record **MUST** be done with `db.updateRecord()`. For
faster processing and to avoid unwanted changes, the returned record by any method of the API is a
copy of the original one, with `id` property being read-only.


```coffee
  # Constructs a new instance of {Database}
  #
  # @param {String} basePath              the base path for the db files, hosting base JSON files of any added overlay
  # @option config {String} createdAtKey  name of the key to use as the `createdAt` flag for a record
  # @option config {String} updatedAtKey  name of the key to use as the `updatedAt` flag for a record
  # @option config {String} deletedAtKey  name of the key to use as the `deletedAt` flag for a record (default `__deleted`)
  db = new Database(basePath = './json.db', config = {})

  # Add an overlay on top of all layers (the latest is the one used first, then come the others in order until the base)
  #
  # @param {String} path  the path where to read/write JSON files of records, relative to the base path
  # @return {Database}    this object for chaining
  db.addOverlay(path)

  # Creates a new record in the database
  #
  # @param {String} modelName name of the model
  # @param {Object} record    attributes of the record to create
  # @return {Object}          a copy of the newly created model with read-only `id`
  db.createRecord(modelName, record)

  # Updates a record with the given attributes
  #
  # @overload updateModel(modelName, id, record)
  #   @param {String} modelName   name of the model
  #   @param {String, Number} id  id of the record to update
  #   @param {Object} record      attributes of the record to update
  #   @return {Object}            a copy of the updated record
  #
  # @overload updateModel(modelName, record)
  #   @param {String} modelName   name of the model
  #   @param {Object} record      attributes of the record to update (including its id)
  #   @return {Object}            a copy of the updated record
  db.updateRecord(modelName, id, record)

  # Deletes a record given its id
  #
  # @param {String} modelName name of the model
  # @return {Object}          a copy of the old record which has been deleted
  db.deleteRecord(modelName, id)

  # Finds a record by id
  #
  # @param {String} modelName   name of the model
  # @param {String, Number} id  id of the record to find
  # @return {Object, undefined} copy of the record if found, else `undefined`
  db.find(modelName, id)

  # Finds many record given a list of ids. If some records are not found, they'll just be filtered out
  # of the resulting array
  #
  # @overload findMany(modelName, ids...)
  #   @param {String} modelName       name of the model
  #   @param {String, Number} ids...  id of each record to find
  #   @return {Array<Object>}         array containing all found records
  #
  # @overload findMany(modelName, ids)
  #   @param {String} modelName           name of the model
  #   @param {Array<String, Number>} ids  array of id for each record to find
  #   @return {Array<Object>}             array containing all found records
  db.findMany(modelName, ids...)

  # Finds records using a filter (either function or set of properties to match)
  #
  # @overlay findQuery(modelName, filter)
  #   @param {String} modelName name of the model
  #   @param {Object} filter    attributes to match
  #   @return {Array<Object>}   array with all records which matched
  #
  # @overlay findQuery(modelName, filter, thisArg)
  #   @param {String} modelName name of the model
  #   @param {Function} filter  function used to filter records, each record is given as the first parameter
  #   @param {Object} thisArg   optional, will be used as the context to run the filter function
  #   @return {Array<Object>}   array with all records which matched
  db.findQuery(modelName, filter, thisArg)

  # Finds all records in the database
  #
  # @param {String} modelName name of the model
  # @return {Array<Object>}   array containing all records of the given model
  db.findAll(modelName)

  # Counts all records of a given model
  #
  # @param {String} modelName name of the model to count records
  # @return {Number}          the total number of records
  db.count(modelName)

  # Saves in the top overlay's path the records that have been created/modified or deleted
  #
  # @return {Database} this object for chaining
  db.save()
```
