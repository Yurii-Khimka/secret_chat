import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secret_chat/security/activation.dart';
import 'package:secret_chat/security/activation_controller.dart';

Future<String> _buildValidCode(SimpleKeyPairData keyPair) async {
  final algorithm = Ed25519();
  final payloadJson = '{"id":"test","iat":${DateTime.now().millisecondsSinceEpoch ~/ 1000}}';
  final payloadBytes = utf8.encode(payloadJson);
  final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);
  return '${base64Url.encode(payloadBytes)}.${base64Url.encode(signature.bytes)}';
}

void main() {
  late SimpleKeyPairData keyPair;
  late List<int> pubBytes;

  setUp(() async {
    final algorithm = Ed25519();
    keyPair = await algorithm.newKeyPair() as SimpleKeyPairData;
    final publicKey = await keyPair.extractPublicKey();
    pubBytes = publicKey.bytes;
    setActivationPublicKeyForTesting(pubBytes);
  });

  tearDown(() => setActivationPublicKeyForTesting(null));

  group('ActivationController', () {
    test('load() with empty prefs → activated == false', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ActivationController();
      await controller.load();
      expect(controller.activated, isFalse);
    });

    test('load() with valid persisted code → activated == true', () async {
      final code = await _buildValidCode(keyPair);
      SharedPreferences.setMockInitialValues({'activation.code': code});
      final controller = ActivationController();
      await controller.load();
      expect(controller.activated, isTrue);
    });

    test('load() with tampered persisted code → activated == false, prefs cleared', () async {
      SharedPreferences.setMockInitialValues({'activation.code': 'garbage.garbage'});
      final controller = ActivationController();
      await controller.load();
      expect(controller.activated, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('activation.code'), isNull);
    });

    test('activate() with valid code → returns true, activated, persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ActivationController();
      await controller.load();

      final code = await _buildValidCode(keyPair);
      final result = await controller.activate(code);

      expect(result, isTrue);
      expect(controller.activated, isTrue);
      expect(controller.error, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('activation.code'), isNotNull);
    });

    test('activate() with invalid code → returns false, error set, prefs unchanged', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ActivationController();
      await controller.load();

      final result = await controller.activate('bad.code');

      expect(result, isFalse);
      expect(controller.activated, isFalse);
      expect(controller.error, equals('[ERROR] code not valid'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('activation.code'), isNull);
    });

    test('clearError() resets error to null without touching activated', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ActivationController();
      await controller.load();

      await controller.activate('bad.code');
      expect(controller.error, isNotNull);

      controller.clearError();
      expect(controller.error, isNull);
      expect(controller.activated, isFalse);
    });
  });
}
