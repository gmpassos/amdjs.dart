import 'dart:async';
import 'dart:js_interop_unsafe';

import 'package:dom_tools/dom_tools.dart';

@JS('define')
external JSAny? get _jsDefine;

@JS('require')
external JSAny? get _jsRequire;

extension type _RequireConfigPaths._(JSObject o) implements JSObject {
  external _RequireConfigPaths({JSObject paths});

  external JSObject get paths;
}

extension type _RequireConfigPackages._(JSObject o) implements JSObject {
  external _RequireConfigPackages({JSArray<JSObject> packages});

  external JSArray<JSObject> get packages;
}

@JS('require.config')
external void _jsSetRequireConfig(JSObject config);

@JS('require')
external void _jsCallRequire(
    JSArray<JSString> modules, JSFunction onSuccess, JSFunction onError);

/// JavaScript AMD (Asynchronous Module Definition) Dart interoperability.
class AMDJS {
  /// verbose: If true logs usage to console.
  static bool verbose = true;

  static void _log(bool native, String msg) {
    if (verbose) {
      var prefix = native ? '[AMD native imp.]' : '[AMD Dart mimic]';
      print('$prefix $msg');
    }
  }

  /// Ensures that this class and JS interoperability is loaded. You don't need
  /// to call this function, since it's already called internally by the API.
  ///
  /// **Don't needed anymore (using package `dart:js_interop`).
  /// Innocuous, always return `true`.**
  @Deprecated("Don't needed anymore (using package `dart:js_interop`).")
  static Future<bool> load() {
    return Future.value(true);
  }

  static bool isNativeImplementationPresent() {
    final definedPresent = _jsDefine.isA<JSFunction>();
    final requirePresent = _jsRequire.isA<JSFunction>();
    return definedPresent && requirePresent;
  }

  static void _callRequire(JSObject config, List<String> names,
      String? globalName, void Function(dynamic) callback) {
    _jsSetRequireConfig(config);

    _jsCallRequire(
      names.toJS,
      (JSAny? r) {
        if (globalName != null && r != null) {
          var val = globalContext[globalName];
          if (val == null || val.isUndefinedOrNull) {
            globalContext[globalName] = r;
          }
        }
        callback(true);
      }.toJS,
      (JSAny? err) {
        callback(err.toString());
      }.toJS,
    );
  }

  static void requireModuleNativeByPath(String name, String path,
      String? globalName, void Function(dynamic) callback) {
    final config = _RequireConfigPaths(paths: {name: path}.toJSDeep);
    _callRequire(config, [name], globalName, callback);
  }

  static void requireModuleNativeByPackage(List<String> names, String location,
      String subPath, String? globalName, void Function(dynamic) callback) {
    // Create the configuration object with packages
    final config = _RequireConfigPackages(
        packages: [
      {
        'name': names[0],
        'location': location,
        'main': subPath,
      }.toJSDeep
    ].toJS);

    _callRequire(config, names, globalName, callback);
  }

  /// Tries to load a [module] using native AMD using [jsFullPath]. Is
  /// recommended to use the function [require], that calls [requireNative]
  /// only if is really needed.
  ///
  /// Throws [StateError] if native mode is not detected.
  static Future<bool> requireNativeByPath(String module, String jsFullPath,
      {String? globalJSVariableName}) async {
    var nativePresent = isNativeImplementationPresent();

    if (!nativePresent) {
      throw StateError('AMD native implementation not present');
    }

    if (jsFullPath.toLowerCase().endsWith('.js')) {
      jsFullPath = jsFullPath.substring(0, jsFullPath.length - 3);
    }

    var completer = Completer<bool>();

    requireModuleNativeByPath(module, jsFullPath, globalJSVariableName, (r) {
      var ok = r == true;
      _log(true, "Module '$module' loaded[by path]> ok: $ok");
      completer.complete(ok);
    });

    return completer.future;
  }

  /// Tries to load a [module] using native AMD using package/module
  /// configuration. Is recommended to use the function [require],
  /// that calls [requireNative] only if is really needed.
  ///
  /// Throws [StateError] if native mode is not detected.
  static Future<bool> requireNativeByPackage(
      List<String> modules, String jsLocation, jsSubPath,
      {String? globalJSVariableName}) async {
    var nativePresent = isNativeImplementationPresent();

    if (!nativePresent) {
      throw StateError('AMD native implementation not present');
    }

    if (jsSubPath.toLowerCase().endsWith('.js')) {
      jsSubPath = jsSubPath.substring(0, jsSubPath.length - 3);
    }

    var completer = Completer<bool>();

    requireModuleNativeByPackage(
        modules, jsLocation, jsSubPath, globalJSVariableName, (r) {
      var ok = r == true;
      _log(true, "Modules '$modules' loaded[by package]> ok: $ok");
      completer.complete(ok);
    });

    return completer.future;
  }

  /// Requires a [module] that can be found at [jsFullPath]. Returns true if OK.
  static Future<bool> require(dynamic modules,
      {String? jsFullPath,
      String? jsLocation,
      String? jsSubPath,
      String? globalJSVariableName,
      bool addScriptTagInsideBody = false}) async {
    var modulesList = <String>[];

    if (modules is String) {
      modulesList.add(modules);
    } else if (modules is Iterable) {
      modulesList.addAll(modules.where((e) => e != null).map((e) => '$e'));
    }

    modulesList.removeWhere((e) => e.isEmpty);

    if (isNativeImplementationPresent()) {
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
      String? jsLocation,
      String? jsSubPath,
      String? jsFullPath) {
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
    String? jsLocation;
    String? jsPath;

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
    var okJS = await addJavaScriptSource(jsPath,
        addToBody: addScriptTagInsideBody, async: true);
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
