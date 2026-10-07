@TestOn('browser')
library;

import 'dart:js_interop_unsafe';

import 'package:amdjs/amdjs.dart';
import 'package:dom_tools/dom_tools.dart';
import 'package:test/test.dart';

/// Integration tests with a native AMD implementation (RequireJS).
void main() {
  group('AMDJS (native: RequireJS)', () {
    setUpAll(() async {
      expect(AMDJS.isNativeImplementationPresent(), isFalse);
      expect(await addJavaScriptSource('js/require.min.js'), isTrue);
    });

    JSObject global(String name) => globalContext[name] as JSObject;

    test('isNativeImplementationPresent', () {
      expect(AMDJS.isNativeImplementationPresent(), isTrue);
    });

    test('require by path + globalJSVariableName', () async {
      var ok = await AMDJS.require(
        'amdCalc',
        jsFullPath: 'js/amd-calc.js',
        globalJSVariableName: 'amdCalc',
      );
      expect(ok, isTrue);

      var calc = global('amdCalc');
      expect(
        calc.callMethod<JSNumber>('mul'.toJS, 3.toJS, 4.toJS).toDartInt,
        equals(12),
      );
      expect(
        calc.callMethod<JSNumber>('add'.toJS, 3.toJS, 4.toJS).toDartInt,
        equals(7),
      );
    });

    test(
      'globalJSVariableName does not overwrite an existing global',
      () async {
        globalContext['amdCalcExisting'] = 'keep'.toJS;

        var ok = await AMDJS.requireNativeByPath(
          'amdCalc',
          'js/amd-calc',
          globalJSVariableName: 'amdCalcExisting',
        );
        expect(ok, isTrue);
        expect(globalContext['amdCalcExisting'].dartify(), equals('keep'));
      },
    );

    test('module with AMD dependency', () async {
      // `amd-dep.js` depends on module `amdCalc` (already configured):
      var ok = await AMDJS.require(
        'amdDep',
        jsFullPath: 'js/amd-dep',
        globalJSVariableName: 'amdDep',
      );
      expect(ok, isTrue);
      expect(
        global('amdDep').callMethod<JSNumber>('square'.toJS, 5.toJS).toDartInt,
        equals(25),
      );
    });

    test('require by package (jsLocation + jsSubPath)', () async {
      var ok = await AMDJS.require(
        'pkgGreet',
        jsLocation: 'js/pkg-greet',
        jsSubPath: 'main.js',
        globalJSVariableName: 'pkgGreet',
      );
      expect(ok, isTrue);
      expect(
        global(
          'pkgGreet',
        ).callMethod<JSString>('greet'.toJS, 'AMD'.toJS).toDart,
        equals('Hello AMD'),
      );
    });

    test('missing module', () async {
      var ok = await AMDJS
          .require('noSuchModule', jsFullPath: 'js/no-such-module.js')
          .timeout(Duration(seconds: 15));
      expect(ok, isFalse);
    });

    test('invalid arguments', () async {
      expect(
        () => AMDJS.require(['a', 'b'], jsFullPath: 'js/amd-calc.js'),
        throwsArgumentError,
      );
      expect(() => AMDJS.require('x'), throwsArgumentError);
    });
  });
}
