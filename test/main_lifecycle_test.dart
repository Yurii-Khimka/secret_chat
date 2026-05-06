import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_chat/main.dart';

void main() {
  group('shouldCloseOnLifecycle', () {
    test('paused does not trigger close', () {
      expect(shouldCloseOnLifecycle(AppLifecycleState.paused), false);
    });

    test('inactive does not trigger close', () {
      expect(shouldCloseOnLifecycle(AppLifecycleState.inactive), false);
    });

    test('hidden does not trigger close', () {
      expect(shouldCloseOnLifecycle(AppLifecycleState.hidden), false);
    });

    test('detached triggers close', () {
      expect(shouldCloseOnLifecycle(AppLifecycleState.detached), true);
    });
  });
}
