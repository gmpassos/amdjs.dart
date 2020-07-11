@TestOn('browser')
import 'package:amdjs/amdjs.dart';
import 'package:test/test.dart';

void main() {
  group('AMDJS', () {
    setUp(() {});

    test('isNativeImplementationPresent', () async {
      expect(await AMDJS.isNativeImplementationPresent(), equals(false));
    });
  });
}
