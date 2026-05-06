import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_chat/network/crypto.dart';

void main() {
  group('deriveKey', () {
    test('is deterministic for same (phrase, roomCode)', () async {
      final key1 = await deriveKey(phrase: 'secret', roomCode: 'WOLF-1234');
      final key2 = await deriveKey(phrase: 'secret', roomCode: 'WOLF-1234');
      expect(key1, equals(key2));
    });

    test('different phrases produce different keys', () async {
      final key1 = await deriveKey(phrase: 'alpha', roomCode: 'WOLF-1234');
      final key2 = await deriveKey(phrase: 'beta', roomCode: 'WOLF-1234');
      expect(key1, isNot(equals(key2)));
    });

    test('different roomCodes produce different keys (same phrase)', () async {
      final key1 = await deriveKey(phrase: 'secret', roomCode: 'WOLF-1234');
      final key2 = await deriveKey(phrase: 'secret', roomCode: 'BEAR-5678');
      expect(key1, isNot(equals(key2)));
    });

    test('produces 32-byte key', () async {
      final key = await deriveKey(phrase: 'test', roomCode: 'FOX-0001');
      expect(key.length, 32);
    });
  });

  group('encryptMessage / decryptMessage', () {
    late Uint8List key;

    setUp(() async {
      key = await deriveKey(phrase: 'passphrase', roomCode: 'ROOM-9999');
    });

    test('round-trip recovers plaintext', () async {
      final result = await encryptMessage(plaintext: 'hello world', key: key);
      final decrypted = await decryptMessage(
        ciphertextBase64: result.ciphertext,
        nonceBase64: result.nonce,
        key: key,
      );
      expect(decrypted, 'hello world');
    });

    test('decrypt with wrong key returns null', () async {
      final result = await encryptMessage(plaintext: 'hello', key: key);
      final wrongKey = await deriveKey(phrase: 'wrong', roomCode: 'ROOM-9999');
      final decrypted = await decryptMessage(
        ciphertextBase64: result.ciphertext,
        nonceBase64: result.nonce,
        key: wrongKey,
      );
      expect(decrypted, isNull);
    });

    test('decrypt with malformed base64 returns null', () async {
      final decrypted = await decryptMessage(
        ciphertextBase64: '!!!not-base64!!!',
        nonceBase64: '!!!also-bad!!!',
        key: key,
      );
      expect(decrypted, isNull);
    });

    test('nonce is 24 bytes after base64 decode', () async {
      final result = await encryptMessage(plaintext: 'test', key: key);
      final nonceBytes = base64.decode(result.nonce);
      expect(nonceBytes.length, 24);
    });

    test('each encryption produces a different nonce', () async {
      final r1 = await encryptMessage(plaintext: 'same', key: key);
      final r2 = await encryptMessage(plaintext: 'same', key: key);
      expect(r1.nonce, isNot(equals(r2.nonce)));
    });
  });
}
