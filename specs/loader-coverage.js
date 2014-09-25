if (process.env.COVERAGE) {
  require('coffee-coverage').register({
    path: 'relative',
    basePath: require('path').join(__dirname, '..'),
    exclude: ['specs', 'node_modules', '.git', '.idea', 'lib', 'docs'],
    initAll: true
  });
}
require('./loader');
