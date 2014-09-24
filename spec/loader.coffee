sysPath = require 'path'
_ = require 'lodash'
chai = require 'chai'

GLOBAL.expect = expect = chai.expect
GLOBAL.sinon = sinon = require 'sinon'
GLOBAL.lib = lib = require '..'


# ==== chai configuration =============

# disable truncating
chai.config.truncateThreshold = 0
