(function () {
  "use strict";
  var chai = require('chai');
  var useSources = (process.env.TEST_WITH_SOURCES || process.env.COVERAGE);

  require('coffee-script').register();

  // if NODE_ENV is test, then we are sure that we are using the sources directly
  if (process.env.COVERAGE) {
    require('coffee-coverage').register({
      path:     'relative',
      basePath: require('path').join(__dirname, '..'),
      exclude:  ['specs', 'node_modules', '.git', '.idea', 'lib', 'docs'],
      initAll:  true
    });
  }

  this.expect = chai.expect;
  this.sinon = require('sinon');
  this.lib = require('../' + (useSources ? 'src' : 'lib'));


  /* ==== chai configuration ============= */

  // disable truncating
  chai.config.truncateThreshold = 0;
}).call(GLOBAL);
