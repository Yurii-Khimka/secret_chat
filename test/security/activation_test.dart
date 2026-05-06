import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_chat/security/activation.dart';

void main() {
  tearDown(() => setActivationPublicKeyForTesting(null));

  group('verifyActivationCode', () {
    test('round-trip: sign and verify with correct key', () async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      setActivationPublicKeyForTesting(publicKey.bytes);

      final payloadJson = '{"id":"abc","iat":1000}';
      final payloadBytes = utf8.encode(payloadJson);
      final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);

      final code = '${base64Url.encode(payloadBytes)}.${base64Url.encode(signature.bytes)}';
      expect(await verifyActivationCode(code), isTrue);
    });

    test('wrong key: sign with A, verify with B → false', () async {
      final algorithm = Ed25519();
      final keyPairA = await algorithm.newKeyPair();
      final keyPairB = await algorithm.newKeyPair();
      final publicKeyB = await keyPairB.extractPublicKey();
      setActivationPublicKeyForTesting(publicKeyB.bytes);

      final payloadJson = '{"id":"abc","iat":1000}';
      final payloadBytes = utf8.encode(payloadJson);
      final signature = await algorithm.sign(payloadBytes, keyPair: keyPairA);

      final code = '${base64Url.encode(payloadBytes)}.${base64Url.encode(signature.bytes)}';
      expect(await verifyActivationCode(code), isFalse);
    });

    test('tampered payload → false', () async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      setActivationPublicKeyForTesting(publicKey.bytes);

      final payloadJson = '{"id":"abc","iat":1000}';
      final payloadBytes = utf8.encode(payloadJson);
      final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);

      // Tamper payload.
      final tamperedPayload = '{"id":"xyz","iat":1000}';
      final code = '${base64Url.encode(utf8.encode(tamperedPayload))}.${base64Url.encode(signature.bytes)}';
      expect(await verifyActivationCode(code), isFalse);
    });

    test('tampered signature → false', () async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      setActivationPublicKeyForTesting(publicKey.bytes);

      final payloadJson = '{"id":"abc","iat":1000}';
      final payloadBytes = utf8.encode(payloadJson);
      final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);

      // Flip a bit in the signature.
      final sigBytes = List<int>.from(signature.bytes);
      sigBytes[0] ^= 0x01;
      final code = '${base64Url.encode(payloadBytes)}.${base64Url.encode(sigBytes)}';
      expect(await verifyActivationCode(code), isFalse);
    });

    test('malformed: no dot → false', () async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      setActivationPublicKeyForTesting(publicKey.bytes);

      expect(await verifyActivationCode('nodothere'), isFalse);
    });

    test('malformed: empty string → false', () async {
      setActivationPublicKeyForTesting(List<int>.filled(32, 1));
      expect(await verifyActivationCode(''), isFalse);
    });

    test('malformed: whitespace only → false', () async {
      setActivationPublicKeyForTesting(List<int>.filled(32, 1));
      expect(await verifyActivationCode('   \n  '), isFalse);
    });

    test('malformed: multiple dots, only first is used', () async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      setActivationPublicKeyForTesting(publicKey.bytes);

      // Build a valid code, then append extra dot — sig part includes the trailing dot+garbage.
      expect(await verifyActivationCode('a.b.c'), isFalse);
    });

    test('wrong signature length → false', () async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      setActivationPublicKeyForTesting(publicKey.bytes);

      final payloadJson = '{"id":"abc","iat":1000}';
      final payloadBytes = utf8.encode(payloadJson);
      // Only 32 bytes, not 64.
      final code = '${base64Url.encode(payloadBytes)}.${base64Url.encode(List<int>.filled(32, 0))}';
      expect(await verifyActivationCode(code), isFalse);
    });

    test('placeholder pubkey (all zeros) → false', () async {
      setActivationPublicKeyForTesting(List<int>.filled(32, 0));

      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final payloadJson = '{"id":"abc","iat":1000}';
      final payloadBytes = utf8.encode(payloadJson);
      final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);

      final code = '${base64Url.encode(payloadBytes)}.${base64Url.encode(signature.bytes)}';
      expect(await verifyActivationCode(code), isFalse);
    });

    test('whitespace tolerance: leading/trailing whitespace and newlines', () async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      setActivationPublicKeyForTesting(publicKey.bytes);

      final payloadJson = '{"id":"abc","iat":1000}';
      final payloadBytes = utf8.encode(payloadJson);
      final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);

      final cleanCode = '${base64Url.encode(payloadBytes)}.${base64Url.encode(signature.bytes)}';
      final dirtyCode = '  \n $cleanCode \n  ';
      expect(await verifyActivationCode(dirtyCode), isTrue);
    });
  });
}
