// ==UserScript==
// @id             sh-enl-service-auth@Breezewish
// @name           IITC plugin: SH ENL Service Auth
// @description    Authorize to Shanghai Enlightened Service
// @author         Breezewish
// @category       Layer
// @version        0.0.1.20140328.102500
// @namespace      https://github.com/jonatkins/ingress-intel-total-conversion
// @include        https://www.ingress.com/intel*
// @include        http://www.ingress.com/intel*
// @match          https://www.ingress.com/intel*
// @match          http://www.ingress.com/intel*
// @grant          none
// ==/UserScript==


function wrapper(plugin_info) {
// ensure plugin framework is there, even if iitc is not yet loaded
if(typeof window.plugin !== 'function') window.plugin = function() {};


// PLUGIN START ////////////////////////////////////////////////////////

// Basic helper functions and declarations

window.plugin.SHENLAuth = function() {};
window.plugin.SHENLAuth.localStoragePrefix = 'sh-enl-service-';
window.plugin.SHENLAuth.serviceAddress = 'http://localhost:21474'; //'https://shenl.vijos.org';
window.plugin.SHENLAuth.plextCenter = {
  lat: 31.03999175758115,
  lng: 121.75048828124999
};

window.plugin.SHENLAuth.request = function(opt) {
  // make a copy
  var options = jQuery.extend({}, opt);
  // add some other things..
  options.url = window.plugin.SHENLAuth.serviceAddress + options.url
  options.crossDomain = true;
  options.dataType = 'json';
  jQuery.ajax(options);
}

Array.prototype.forEach.call(['POST', 'GET', 'PUT', 'DELETE'], function(method) {
  window.plugin.SHENLAuth[method] = function(opt) {
    var options = jQuery.extend({}, opt);
    options.type = method;
    window.plugin.SHENLAuth.request(options);
  }
});

window.plugin.SHENLAuth.get = function(name) {
  var iname = window.plugin.SHENLAuth.localStoragePrefix + name;
  return JSON.parse(localStorage.getItem(iname));
}

window.plugin.SHENLAuth.set = function(name, value) {
  var iname = window.plugin.SHENLAuth.localStoragePrefix + name;
  localStorage.setItem(iname, JSON.stringify(value));
}

// Body

window.plugin.SHENLAuth.token = null;
window.plugin.SHENLAuth.token = window.plugin.SHENLAuth.get('access-token') || null;

window.plugin.SHENLAuth.authorize = function(callback) {
  window.plugin.SHENLAuth.getToken(PLAYER.nickname, function(err, data) {
    if (err) {
      return callback(err);
    }
    if (data.token) {
      window.plugin.SHENLAuth.sendTokenValidation(data.token, callback);
    }
  });
}

window.plugin.SHENLAuth.getToken = function(agent, callback) {
  window.plugin.SHENLAuth.POST({
    url: '/auth/token/' + agent,
    success: function(data) {
      if (data.error) {
        return callback(data.error);
      }
      callback(null, data);
    },
    error: function(data, status, error) {
      callback(error);
    }
  });
}

window.plugin.SHENLAuth.sendTokenValidation = function(token, callback) {
  var data = {
    message:  '#bot [validate] ' + token,
    latE6:    Math.round((window.plugin.SHENLAuth.plextCenter.lat + Math.random() * 0.05) * 1e6),
    lngE6:    Math.round((window.plugin.SHENLAuth.plextCenter.lng + Math.random() * 0.05) * 1e6),
    chatTab: 'faction'
  };

  function stopAndReturn(err, data) {
    if (t != null) {
      clearInterval(t);
      t = null;  
    }
    callback(err, data);
  }

  function statusChecker() {
    window.plugin.SHENLAuth.GET({
      url: '/auth/token/' + token,
      success: function(data) {
        if (data.error) {
          return stopAndReturn(data.error);
        }
        if (data.access_level == 'LEVEL_VALIDATED') {
          stopAndReturn(null, data);
        }

        // ELSE: not validated...
        t = setTimeout(statusChecker, 10000);
      },
      error: function(data, status, error) {
        stopAndReturn(error);
      }
    });
  }

  var t = null;

  window.postAjax('sendPlext', data, function(response) {
    if (response.error) {
      return stopAndReturn(response.error);
    }
    t = setTimeout(statusChecker, 10000);
  }, function() {
    stopAndReturn('Unable to send request to ingress server');
  });
}

var setup = function() {
  
  if (window.plugin.SHENLAuth.token === null && PLAYER.team === 'ENLIGHTENED') {
    dialog({
      html: 'Your current session hasn\'t granted access permissions.<br>Please click the button to send authorization requests.<br><br>Current user: ' + PLAYER.nickname,
      title: '[SHENL] Authorization required',
      id: 'auth-dialog',
      width: 400,
      buttons: {
        'AUTHORIZE!': function() {
          window.plugin.SHENLAuth.authorize(function(err, data) {
            if (err) {
              alert(err);
            }
            window.plugin.SHENLAuth.set('access-token', data.token);
            alert('Authorization succeeded! Your access-token has been saved locally.');
          });
          $(this).dialog('close');
          alert('Authorization in progress. Please wait NO LESS than 1 minute.\n(You can close this dialog)');
        },
      }
    });
  }
  
}

// PLUGIN END //////////////////////////////////////////////////////////


setup.info = plugin_info; //add the script info data to the function as a property
if(!window.bootPlugins) window.bootPlugins = [];
window.bootPlugins.push(setup);
// if IITC has already booted, immediately run the 'setup' function
if(window.iitcLoaded && typeof setup === 'function') setup();
} // wrapper end
// inject code into site context
var script = document.createElement('script');
var info = {};
if (typeof GM_info !== 'undefined' && GM_info && GM_info.script) info.script = { version: GM_info.script.version, name: GM_info.script.name, description: GM_info.script.description };
script.appendChild(document.createTextNode('('+ wrapper +')('+JSON.stringify(info)+');'));
(document.body || document.head || document.documentElement).appendChild(script);