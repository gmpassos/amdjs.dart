import 'dart:async';
import 'dart:js';

import 'package:dom_tools/dom_tools.dart';
import 'package:swiss_knife/swiss_knife.dart';

/// JavaScript AMD (Asynchronous Module Definition) Dart interoperability.
class AMDJS {
  static bool _verbose = true;

  static bool get verbose => _verbose;

  /// verbose: If true logs usage to console.
  static set verbose(bool value) {
    _verbose = value ?? false;
  }

  static void _log(bool native, String msg) {
    if (verbose) {
      var prefix = native ? '[AMD native imp.]' : '[AMD Dart mimic]';
      print('$prefix $msg');
    }
  }

  static final LoadController _load = LoadController('AMDJS');

  /// Ensures that this class and JS interoperability is loaded. You don't need
  /// to call this function, since it's already called internally by the API.
  static Future<bool> load() {
    return _load.load(() async {
      var okJs = await evalJS('''
          
          __AMDJS__isNativeImplementationPresent = function() {
              var definedPresent = ((typeof define === 'function') && define.amd) ;
              var requirePresent = (typeof require === 'function') ;
              return definedPresent && requirePresent ;
          }
          
          __AMDJS__requireModuleNative = function(name, path, globalName, callback) {
              var conf = { paths: {} };
              conf['paths'][name] = path ;
             
              require.config(conf);
              
              require(
                  [name] ,
                  function(r) {
                      if ( globalName != null ) {
                        if ( r && !window[globalName] ) {
                          window[globalName] = r ;
                        }
                      }
                      
                      callback(true) ;
                  } ,
                  function(err) {
                      callback( ''+err ) ;
                  }
              );
          }
      
      ''');

      return okJs;
    });
  }

  /// Returns true if native JS AMD is detected:
  static Future<bool> isNativeImplementationPresent() async {
    await load();
    var present =
        context.callMethod('__AMDJS__isNativeImplementationPresent') as bool;
    return present;
  }

  /// Tries to load a [module] using native AMD using [jsFullPath]. Is
  /// recommended to use the function [require], that calls this native version
  /// only if is really needed.
  ///
  /// Throws [StateError] if native mode is not detected.
  static Future<bool> requireNative(String module, String jsFullPath,
      {String globalJSVariableName}) async {
    await load();

    var nativePresent = await isNativeImplementationPresent();

    if (!nativePresent) {
      throw StateError('AMD native implementation not present');
    }

    if (jsFullPath.toLowerCase().endsWith('.js')) {
      jsFullPath = jsFullPath.substring(0, jsFullPath.length - 3);
    }

    var completer = Completer<bool>();

    context.callMethod('__AMDJS__requireModuleNative', [
      module,
      jsFullPath,
      globalJSVariableName,
      (r) {
        var ok = r == true;
        _log(true, "Module '$module' loaded> ok: $ok");
        completer.complete(ok);
      }
    ]) as bool;

    return completer.future;
  }

  /// Requires [module] that can by found at [jsFullPath]. Returns true if OK.
  static Future<bool> require(String module, String jsFullPath,
      {String globalJSVariableName,
      bool addScriptTagInsideBody = false}) async {
    bool okJS;

    if (await isNativeImplementationPresent()) {
      _log(true, "Loading module '$module': $jsFullPath");
      okJS = await requireNative(module, jsFullPath,
          globalJSVariableName: globalJSVariableName);
    } else {
      addScriptTagInsideBody ??= false;

      if (!jsFullPath.toLowerCase().endsWith('.js')) {
        jsFullPath += '.js';
      }

      _log(false, "Loading module '$module': $jsFullPath");
      okJS = await addJavaScriptSource(jsFullPath, addScriptTagInsideBody);
      _log(false, "Module '$module' loaded> ok: $okJS");
    }

    return okJS;
  }
}
