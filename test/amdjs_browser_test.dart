@TestOn('browser')
library;

import 'dart:js_interop_unsafe';

import 'package:amdjs/amdjs.dart';
import 'package:dom_tools/dom_tools.dart';
import 'package:test/test.dart';

/// Tests the Dart mimic implementation (no native AMD/RequireJS present).
void main() {
  group('AMDJS', () {
    setUp(() {});

    test('isNativeImplementationPresent', () async {
      expect(AMDJS.isNativeImplementationPresent(), equals(false));
    });

    test('load (deprecated)', () async {
      // ignore: deprecated_member_use_from_same_package
      expect(await AMDJS.load(), isTrue);
    });

    test('libFoo', () async {
      var requireOk = await AMDJS.require('libFoo', jsFullPath: 'lib-foo-test');

      expect(requireOk, isTrue);

      var result = callJSFunction('libFoo', [2, 3]);

      expect(result, equals(6));
    });

    test('jsFullPath with `.js` suffix', () async {
      var requireOk = await AMDJS.require(
        'plainSum',
        jsFullPath: 'js/plain-sum.js',
      );
      expect(requireOk, isTrue);
      expect(callJSFunction('plainSum', [2, 3]), equals(5));
    });

    test('same module loaded only once', () async {
      expect(
        await AMDJS.require('plainSum', jsFullPath: 'js/plain-sum.js'),
        isTrue,
      );
      expect(
        await AMDJS.require('plainSum', jsFullPath: 'js/plain-sum.js'),
        isTrue,
      );
      expect(globalContext['plainSumLoadCount'].dartify(), equals(1));
    });

    test('script tag inside body', () async {
      var requireOk = await AMDJS.require(
        'libFooBody',
        jsFullPath: 'lib-foo-test.js?body',
        addScriptTagInsideBody: true,
      );
      expect(requireOk, isTrue);
      var body = (globalContext['document'] as JSObject)['body'] as JSObject;
      expect(
        body.callMethod<JSAny?>(
          'querySelector'.toJS,
          'script[src*="lib-foo-test.js?body"]'.toJS,
        ),
        isNotNull,
      );
    });

    test('jsLocation + jsSubPath with sub-modules', () async {
      var requireOk = await AMDJS.require(
        ['mimicMain', '/ext', null, ''],
        jsLocation: 'js/mimic/',
        jsSubPath: '/main',
      );
      expect(requireOk, isTrue);
      expect(callJSFunction('mimicMain'), equals('main'));
      expect(callJSFunction('mimicExt'), equals('ext'));
    });

    test('missing script', () async {
      var requireOk = await AMDJS
          .require('noSuchModule', jsFullPath: 'js/no-such-module.js')
          .timeout(Duration(seconds: 10));
      expect(requireOk, isFalse);
    });

    test('invalid arguments', () async {
      expect(() => AMDJS.require('x'), throwsArgumentError);
      expect(
        () => AMDJS.require('x', jsLocation: 'js', jsSubPath: ''),
        throwsArgumentError,
      );
    });

    test('native functions throw without native AMD', () async {
      expect(() => AMDJS.requireNativeByPath('x', 'js/x.js'), throwsStateError);
      expect(
        () => AMDJS.requireNativeByPackage(['x'], 'js', 'x'),
        throwsStateError,
      );
    });

    test('verbose', () async {
      var prev = AMDJS.verbose;
      try {
        AMDJS.verbose = false;
        expect(
          await AMDJS.require('libFoo', jsFullPath: 'lib-foo-test'),
          isTrue,
        );
      } finally {
        AMDJS.verbose = prev;
      }
    });
  });
}
