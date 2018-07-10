const merge = require('webpack-merge');
const webpack = require('webpack');

const common = require('./webpack.common');

module.exports = merge(common, {
  entry: [
    './index.tsx'
  ],
  devServer: {
    host: '0.0.0.0',
    hot: true, // enable HMR on the server
    historyApiFallback: true,
  },
  devtool: 'cheap-module-eval-source-map',
  plugins: [
    new webpack.NamedModulesPlugin(), // Prints more readable module names in the browser console on HMR updates
    new webpack.HotModuleReplacementPlugin(), // Enable HMR globally
  ],
});
