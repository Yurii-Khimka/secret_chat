import 'package:flutter_test/flutter_test.dart';
import 'package:secret_chat/network/error_messages.dart';

void main() {
  group('describeConnectionError', () {
    test('each known code maps to a non-empty [ERROR] string', () {
      for (final entry in kConnectionErrorMessages.entries) {
        final msg = describeConnectionError(entry.key);
        expect(msg, isNotEmpty);
        expect(msg, startsWith('[ERROR]'));
        expect(msg, entry.value);
      }
    });

    test('unknown code returns generic fallback', () {
      expect(describeConnectionError('xyz_unknown'), '[ERROR] connection failed');
    });

    test('null returns generic fallback', () {
      expect(describeConnectionError(null), '[ERROR] connection failed');
    });

    test('connect_timeout maps correctly', () {
      expect(describeConnectionError('connect_timeout'), '[ERROR] connection timed out');
    });

    test('connection_failed maps correctly', () {
      expect(describeConnectionError('connection_failed'), '[ERROR] could not reach server');
    });
  });
}
