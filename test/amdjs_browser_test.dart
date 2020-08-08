@TestOn('browser')
import 'package:amdjs/amdjs.dart';
import 'package:dom_tools/dom_tools.dart';
import 'package:test/test.dart';

void main() {
  group('AMDJS', () {
    setUp(() {});

    test('isNativeImplementationPresent', () async {
      expect(await AMDJS.isNativeImplementationPresent(), equals(false));
    });

    test('libFoo', () async {
      var requireOk = await AMDJS.require('libFoo', jsFullPath: 'lib-foo-test');

      expect(requireOk, isTrue);

      var result = callFunction('libFoo', [2, 3]);

      expect(result, equals(6));
    });
  });
}
