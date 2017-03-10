const blacklist = require('react-native/packager/blacklist');

module.exports = {
  getBlacklistRE: function() {
    return blacklist([/build\/.*/]);
  }
};