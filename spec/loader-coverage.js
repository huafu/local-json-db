if (process.env.COVERAGE) {
  require('coffee-coverage').register({
    path: 'relative',
    basePath: require('path').join(__dirname, '..'),
    exclude: ['spec', 'node_modules', '.git', '.idea'],
    initAll: true
  });
}
require('./loader');
