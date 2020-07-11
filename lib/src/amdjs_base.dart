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
      var okJs = evalJS('''
          
          __AMDJS__isNativeImplementationPresent = function() {
              var definedPresent = ((typeof define === 'function') && define.amd) ;
              var requirePresent = (typeof require === 'function') ;
              return definedPresent && requirePresent ;
          }
          
          __AMDJS__requireModuleNative_byPath = function(name, path, globalName, callback) {
              var conf = {
                paths: {}
              };
              
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
          
          __AMDJS__requireModuleNative_byPackage = function(names, location, subPath, globalName, callback) {
              var conf = { 
                packages: [{
                  name: names[0],
                  location: location,
                  main: subPath
                }]
              };
              
              require.config(conf);
              
              require(
                  names ,
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

      return okJs != null;
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
  /// recommended to use the function [require], that calls [requireNative]
  /// only if is really needed.
  ///
  /// Throws [StateError] if native mode is not detected.
  static Future<bool> requireNativeByPath(String module, String jsFullPath,
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

    context.callMethod('__AMDJS__requireModuleNative_byPath', [
      module,
      jsFullPath,
      globalJSVariableName,
      (r) {
        var ok = r == true;
        _log(true, "Module '$module' loaded[by path]> ok: $ok");
        completer.complete(ok);
      }
    ]) as bool;

    return completer.future;
  }

  /// Tries to load a [module] using native AMD using package/module
  /// configuration. Is recommended to use the function [require],
  /// that calls [requireNative] only if is really needed.
  ///
  /// Throws [StateError] if native mode is not detected.
  static Future<bool> requireNativeByPackage(
      List<String> modules, String jsLocation, jsSubPath,
      {String globalJSVariableName}) async {
    await load();

    var nativePresent = await isNativeImplementationPresent();

    if (!nativePresent) {
      throw StateError('AMD native implementation not present');
    }

    if (jsSubPath.toLowerCase().endsWith('.js')) {
      jsSubPath = jsSubPath.substring(0, jsSubPath.length - 3);
    }

    var completer = Completer<bool>();

    context.callMethod('__AMDJS__requireModuleNative_byPackage', [
      JsObject.jsify(modules),
      jsLocation,
      jsSubPath,
      globalJSVariableName,
      (r) {
        var ok = r == true;
        _log(true, "Modules '$modules' loaded[by package]> ok: $ok");
        completer.complete(ok);
      }
    ]) as bool;

    return completer.future;
  }

  /// Requires a [module] that can be found at [jsFullPath]. Returns true if OK.
  static Future<bool> require(dynamic modules,
      {String jsFullPath,
      String jsLocation,
      String jsSubPath,
      String globalJSVariableName,
      bool addScriptTagInsideBody = false}) async {
    var modulesList = <String>[];

    if (modules is String) {
      modulesList.add(modules);
    } else if (modules is Iterable) {
      modulesList.addAll(modules.map((e) => '$e'));
    }

    modulesList.removeWhere((e) => e == null || e.isEmpty);

    if (await isNativeImplementationPresent()) {
      bool requireOK;

      if (jsFullPath != null && jsFullPath.isNotEmpty) {
        if (modulesList.length > 1) {
          throw ArgumentError(
              "Can't load using path with multiple modules: $modulesList");
        }

        var mainModule = modulesList.single;
        _log(true, "Loading module '$mainModule': $jsFullPath");

        requireOK = await requireNativeByPath(mainModule, jsFullPath,
            globalJSVariableName: globalJSVariableName);
      } else if (jsLocation != null &&
          jsLocation.isNotEmpty &&
          jsSubPath != null &&
          jsSubPath.isNotEmpty) {
        _log(true, "Loading modules '$modulesList': $jsLocation -> $jsSubPath");
        requireOK = await requireNativeByPackage(
            modulesList, jsLocation, jsSubPath,
            globalJSVariableName: globalJSVariableName);
      } else {
        throw ArgumentError(
            'Invalid JS arguments: empty jsFullPath, jsLocation and jsSubPath');
      }

      return requireOK;
    } else {
      addScriptTagInsideBody ??= false;

      var modulesFullPaths = _resolveModulesFullPath(
          modulesList, jsLocation, jsSubPath, jsFullPath);

      var allOK = true;

      for (var entry in modulesFullPaths.entries) {
        var okJS =
            await _requireMimic(entry.key, entry.value, addScriptTagInsideBody);
        if (!okJS) {
          allOK = false;
        }
      }

      return allOK;
    }
  }

  static Map<String, List<String>> _resolveModulesFullPath(
      List<String> modulesList,
      String jsLocation,
      String jsSubPath,
      String jsFullPath) {
    var modulesFullPaths = <String, List<String>>{};
    var mainModule = modulesList.removeAt(0);

    if (jsLocation != null &&
        jsLocation.isNotEmpty &&
        jsSubPath != null &&
        jsSubPath.isNotEmpty) {
      jsLocation = _trimEndingPath(jsLocation);
      jsSubPath = _trimStartingPath(jsSubPath);

      modulesFullPaths[mainModule] = [jsLocation, jsSubPath];

      for (var subModule in modulesList) {
        subModule = _trimStartingPath(subModule);
        modulesFullPaths[subModule] = [jsLocation, subModule];
      }
    } else if (jsFullPath != null && jsFullPath.isNotEmpty) {
      modulesFullPaths[mainModule] = [jsFullPath];
    } else {
      throw ArgumentError(
          'Invalid JS arguments: empty jsFullPath, jsLocation and jsSubPath');
    }
    return modulesFullPaths;
  }

  static final Map<String, String> _requireMimicPaths = {};

  static Future<bool> _requireMimic(String module, List<String> modulePath,
      bool addScriptTagInsideBody) async {
    String jsLocation;
    String jsPath;

    if (modulePath.length == 2) {
      var subPath = modulePath[1];
      var subPathParts = subPath.split('/');

      for (var i = subPathParts.length; i > 0; i--) {
        var parentModule = subPathParts.sublist(0, i).join('/');
        var parentLocation = _requireMimicPaths[parentModule];

        if (parentLocation != null) {
          subPathParts.setRange(0, 1, [parentLocation]);
          var fixedPath = subPathParts.join('/');

          jsLocation = parentLocation;
          jsPath = fixedPath;

          break;
        }
      }

      jsLocation ??= modulePath[0];
      jsPath ??= modulePath.join('/');
    } else {
      jsLocation = jsPath = modulePath[0];
    }

    _requireMimicPaths[module] = jsLocation;

    _log(false, 'REQUIRE> $module -> $jsLocation -> $jsPath');

    if (!jsPath.toLowerCase().endsWith('.js')) {
      jsPath += '.js';
    }

    _log(false, "Loading module '$module': $jsPath");
    var okJS = await addJavaScriptSource(jsPath, addScriptTagInsideBody);
    _log(false, "Module '$module' loaded> ok: $okJS");
    return okJS;
  }

  static String _trimStartingPath(String jsSubPath) {
    while (jsSubPath.startsWith('/')) {
      jsSubPath = jsSubPath.substring(1);
    }
    return jsSubPath;
  }

  static String _trimEndingPath(String jsLocation) {
    while (jsLocation.endsWith('/')) {
      jsLocation = jsLocation.substring(0, jsLocation.length - 1);
    }
    return jsLocation;
  }
}
