/**
 * Created by huafu on 9/18/14.
 */
if (process.env.NODE_ENV === 'test') {
  require('coffee-script').register();
  module.exports = require('./src');
}
else {
  module.exports = require('./lib');
}
