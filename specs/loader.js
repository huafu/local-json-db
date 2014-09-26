if (process.env.COVERAGE) {
  require('coffee-coverage').register({
    path:     'relative',
    basePath: require('path').join(__dirname, '..'),
    exclude:  ['/specs', '/node_modules', '/.git', '/.idea', '/lib', '/docs'],
    initAll:  true
  });
}

(function () {
  "use strict";
  var chai = require('chai');

  this.expect = chai.expect;
  this.sinon = require('sinon');
  this.lib = require('..');


  /* ==== chai configuration ============= */

  // disable truncating
  chai.config.truncateThreshold = 0;
}).call(GLOBAL);
