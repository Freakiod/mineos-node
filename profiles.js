var logging = require('winston');
var profiles = exports;

var PROFILE_MANIFESTS = {};

var normalizedPath = require("path").join(__dirname, "profiles.d");

profiles.get_profile_manifests = function(reload) {
    if(!reload && PROFILE_MANIFESTS.length)
        logging.info("{0} Profiles already loaded ready to return".format(PROFILE_MANIFESTS.length));
    else {
        var manifests = {};
        logging.info("Load profiles from {0}".format(normalizedPath));
        require("fs").readdirSync(normalizedPath).filter(fn => fn.endsWith('.js')).forEach(function(file) {
          if (!file.match('template.js')) {
            var loadedProfile = require('./profiles.d/' + file);
            if(loadedProfile.profile !== undefined){
              var name = file.split('.')[0];
              manifests[name] = loadedProfile.profile;
            }
          }
        });
        PROFILE_MANIFESTS = manifests
    }
    return PROFILE_MANIFESTS
}
