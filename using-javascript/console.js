define(function() {
  var nativeConsole = {};
  try {
    // for IE 8/9
    if (!window.console) {
      window.console = {
        log:   function() {},
        debug: function() {},
        info:  function() {},
        warn:  function() {},
        error: function() {}
      };
    }
    nativeConsole = console;
  // Firefox throws an exception if you access the console object and it doesn't exist. Wow!
  } catch (e) { }
  return nativeConsole;
});