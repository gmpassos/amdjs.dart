
import 'dart:async';
import 'dart:js';

import 'package:dom_tools/dom_tools.dart';
import 'package:swiss_knife/swiss_knife.dart';


class AMDJS {

  static bool _verbose = true ;

  static bool get verbose => _verbose;
  static set verbose(bool value) {
    _verbose = value ?? false ;
  }

  static void _log(bool native, String msg) {
    if (verbose) {
      var prefix = native ? '[AMD native imp.]' : '[AMD Dart mimic]' ;
      print('$prefix $msg') ;
    }
  }

  static final LoadController _load = LoadController('AMDJS') ;

  static Future<bool> load() {
    return _load.load( () async {

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
      
      ''') ;

      return okJs ;
    } );
  }

  static Future<bool> isNativeImplementationPresent() async {
    await load();
    var present = context.callMethod('__AMDJS__isNativeImplementationPresent') as bool ;
    return present ;
  }

  static Future<bool> requireNative(String name, String path, { String globalJSVariableName }) async {
    await load();

    var nativePresent = await isNativeImplementationPresent() ;

    if ( !nativePresent ) {
      throw StateError('AMD native implementation not present') ;
    }

    if ( path.toLowerCase().endsWith('.js') ) {
      path = path.substring(0 , path.length-3) ;
    }

    var completer = Completer<bool>();

    context.callMethod('__AMDJS__requireModuleNative', [name, path, globalJSVariableName, (r) {
      var ok = r == true ;
      _log(true, "Module '$name' loaded> ok: $ok");
      completer.complete(ok) ;
    }]) as bool ;

    return completer.future ;
  }

  static Future<bool> require(String module , String jsFullPath, { String globalJSVariableName , bool addScriptTagInsideBody = false }) async {
    bool okJS ;

    if ( await isNativeImplementationPresent() ) {
      _log(true, "Loading module '$module': $jsFullPath");
      okJS = await requireNative(module, jsFullPath, globalJSVariableName: globalJSVariableName ) ;
    }
    else {
      addScriptTagInsideBody ??= false ;

      if ( !jsFullPath.toLowerCase().endsWith('.js') ) {
        jsFullPath += '.js' ;
      }

      _log(false, "Loading module '$module': $jsFullPath");
      okJS = await addJavaScriptSource(jsFullPath , addScriptTagInsideBody) ;
      _log(false, "Module '$module' loaded> ok: $okJS");
    }

    return okJS ;
  }

}
