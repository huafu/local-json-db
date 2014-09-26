local-json-db [![Build Status](https://travis-ci.org/huafu/local-json-db.svg?branch=master)](https://travis-ci.org/huafu/local-json-db) [![Coverage Status](https://coveralls.io/repos/huafu/local-json-db/badge.png?branch=master)](https://coveralls.io/r/huafu/local-json-db?branch=master) [![NPM version](https://badge.fury.io/js/local-json-db.png)](http://badge.fury.io/js/local-json-db)
=============

[![NPM](https://nodei.co/npm/local-json-db.png?downloads=true&stars=true)](https://nodei.co/npm/local-json-db/)

# A local JSON database with overlays and optional schema + relations

---

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
db = new ljdb.Database('./data') # by default the db will be in {CWD}/json.db/
db.addOverlay 'local'

user = db.createRecord 'user', name: 'Huafu'

# if a schema is defined, it's possible to automatically link records:
post = db.createRecord 'post', {title: 'my post', author: user}

db.save()
```

or in javascript:

```js
var ljdb = require('local-json-db');
var db = new ljdb.Database('./data'); // by default the db will be in {CWD}/json.db/
db.addOverlay('local');

db.createRecord('user', {name: 'Huafu'});

// if a schema is defined, it's possible to automatically link records:
var post = db.createRecord('post', {title: 'my post', author: user});

db.save();
```

**Full API documentation of `Database` is [here](http://huafu.github.io/local-json-db/classes/Database.html).**

It's important to note that returned records objects by any `Database` method are bare javascript objects,
with, in the case of db with schema, magic properties or functions non enumerable. So you can then
serialize them or iterate other their properties as if they were simple js `Object`.


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


The API documentation can be found [here](http://huafu.github.io/local-json-db/classes/Database.html).

More examples and features on their way ;-)
