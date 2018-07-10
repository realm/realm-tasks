const merge = require('webpack-merge');

const common = require('./webpack.common');

module.exports = merge(common, {
  entry: './index.tsx',
  devtool: 'source-map',
  plugins: [],
});
