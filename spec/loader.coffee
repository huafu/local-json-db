sysPath = require 'path'
_ = require 'lodash'

GLOBAL.expect = expect = require('chai').expect
GLOBAL.sinon = sinon = require 'sinon'

GLOBAL.jsonPath = jsonPath = (path, resolve = no) ->
  unless typeof path is 'string'
    path = sysPath.join path...
  res = sysPath.join(__dirname, 'data', "#{ path }.json")
  if resolve
    res = sysPath.resolve res
  res

GLOBAL.jsonRecord = jsonRecord = (model, id) ->
  path = jsonPath(model.split '.')
  data = require(path)
  if id
    for record in data.records when "#{record.id}" is "#{id}"
      return _.cloneDeep(record)
  else
    return _.cloneDeep(data)
  return undefined

GLOBAL.lib = lib = require '..'
