import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_chat/network/crypto.dart';
import 'package:secret_chat/network/protocol.dart';

void main() {
  group('Protocol wire format', () {
    test('open mode: msgTextFrame has text, no ciphertext', () {
      final frame = msgTextFrame('hello');
      final parsed = jsonDecode(frame) as Map<String, dynamic>;
      expect(parsed['type'], 'msg');
      expect(parsed['text'], 'hello');
      expect(parsed.containsKey('ciphertext'), false);
      expect(parsed.containsKey('nonce'), false);
    });

    test('password mode: msgCipherFrame has ciphertext+nonce, no text', () {
      final frame = msgCipherFrame(ciphertext: 'AAA', nonce: 'BBB');
      final parsed = jsonDecode(frame) as Map<String, dynamic>;
      expect(parsed['type'], 'msg');
      expect(parsed['ciphertext'], 'AAA');
      expect(parsed['nonce'], 'BBB');
      expect(parsed.containsKey('text'), false);
    });

    test('parseFrame: msg with text', () {
      final msg = parseFrame(jsonEncode({'type': 'msg', 'text': 'hi'}));
      expect(msg, isA<MsgMsg>());
      final m = msg as MsgMsg;
      expect(m.text, 'hi');
      expect(m.ciphertext, isNull);
    });

    test('parseFrame: msg with ciphertext+nonce', () {
      final msg = parseFrame(jsonEncode({'type': 'msg', 'ciphertext': 'XX', 'nonce': 'YY'}));
      expect(msg, isA<MsgMsg>());
      final m = msg as MsgMsg;
      expect(m.text, isNull);
      expect(m.ciphertext, 'XX');
      expect(m.nonce, 'YY');
    });

    test('parseFrame: msg with both text and ciphertext returns null', () {
      final msg = parseFrame(jsonEncode({'type': 'msg', 'text': 'hi', 'ciphertext': 'XX', 'nonce': 'YY'}));
      expect(msg, isNull);
    });

    test('parseFrame: msg with neither text nor ciphertext returns null', () {
      final msg = parseFrame(jsonEncode({'type': 'msg'}));
      expect(msg, isNull);
    });
  });

  group('E2E encryption round-trip', () {
    test('matched phrases: encrypt → decrypt recovers plaintext', () async {
      const phrase = 'xerxes';
      const roomCode = 'WOLF-1234';

      final keyA = await deriveKey(phrase: phrase, roomCode: roomCode);
      final keyB = await deriveKey(phrase: phrase, roomCode: roomCode);

      // Keys match
      expect(keyA, equals(keyB));

      // A encrypts
      final encrypted = await encryptMessage(plaintext: 'hello', key: keyA);

      // B decrypts
      final decrypted = await decryptMessage(
        ciphertextBase64: encrypted.ciphertext,
        nonceBase64: encrypted.nonce,
        key: keyB,
      );
      expect(decrypted, 'hello');
    });

    test('mismatched phrases: decrypt returns null', () async {
      const roomCode = 'WOLF-1234';

      final keyA = await deriveKey(phrase: 'xerxes', roomCode: roomCode);
      final keyB = await deriveKey(phrase: 'Xerxes', roomCode: roomCode);

      // Keys differ
      expect(keyA, isNot(equals(keyB)));

      // A encrypts
      final encrypted = await encryptMessage(plaintext: 'hello', key: keyA);

      // B tries to decrypt with wrong key
      final decrypted = await decryptMessage(
        ciphertextBase64: encrypted.ciphertext,
        nonceBase64: encrypted.nonce,
        key: keyB,
      );
      expect(decrypted, isNull);
    });

    test('password-mode first message derives key and encrypts', () async {
      const phrase = 'secret';
      const roomCode = 'BEAR-5678';

      // Simulate: first message typed by user is the phrase
      final key = await deriveKey(phrase: phrase, roomCode: roomCode);
      expect(key.length, 32);

      // Encrypt the phrase itself
      final encrypted = await encryptMessage(plaintext: phrase, key: key);
      expect(encrypted.ciphertext.isNotEmpty, true);
      expect(encrypted.nonce.isNotEmpty, true);

      // Same phrase on other side can decrypt
      final peerKey = await deriveKey(phrase: phrase, roomCode: roomCode);
      final decrypted = await decryptMessage(
        ciphertextBase64: encrypted.ciphertext,
        nonceBase64: encrypted.nonce,
        key: peerKey,
      );
      expect(decrypted, phrase);
    });

    test('subsequent messages encrypted with same key', () async {
      const phrase = 'secret';
      const roomCode = 'FOX-0001';

      final key = await deriveKey(phrase: phrase, roomCode: roomCode);

      // Multiple messages
      final e1 = await encryptMessage(plaintext: 'msg1', key: key);
      final e2 = await encryptMessage(plaintext: 'msg2', key: key);

      // Different nonces
      expect(e1.nonce, isNot(equals(e2.nonce)));

      // Both decrypt correctly with same key
      final d1 = await decryptMessage(ciphertextBase64: e1.ciphertext, nonceBase64: e1.nonce, key: key);
      final d2 = await decryptMessage(ciphertextBase64: e2.ciphertext, nonceBase64: e2.nonce, key: key);
      expect(d1, 'msg1');
      expect(d2, 'msg2');
    });

    test('buffered messages: decrypt after key derivation', () async {
      const phrase = 'secret';
      const roomCode = 'HAWK-9999';

      // Peer A sends 2 messages encrypted with key from same phrase
      final peerKey = await deriveKey(phrase: phrase, roomCode: roomCode);
      final enc1 = await encryptMessage(plaintext: 'buffered1', key: peerKey);
      final enc2 = await encryptMessage(plaintext: 'buffered2', key: peerKey);

      // Local user derives key later (same phrase)
      final localKey = await deriveKey(phrase: phrase, roomCode: roomCode);

      // Drain buffered
      final d1 = await decryptMessage(ciphertextBase64: enc1.ciphertext, nonceBase64: enc1.nonce, key: localKey);
      final d2 = await decryptMessage(ciphertextBase64: enc2.ciphertext, nonceBase64: enc2.nonce, key: localKey);
      expect(d1, 'buffered1');
      expect(d2, 'buffered2');
    });

    test('buffered messages with mismatch: decrypt returns null', () async {
      const roomCode = 'LIME-4444';

      final peerKey = await deriveKey(phrase: 'correct', roomCode: roomCode);
      final enc1 = await encryptMessage(plaintext: 'hidden', key: peerKey);

      // Local derives with wrong phrase
      final localKey = await deriveKey(phrase: 'wrong', roomCode: roomCode);
      final d1 = await decryptMessage(ciphertextBase64: enc1.ciphertext, nonceBase64: enc1.nonce, key: localKey);
      expect(d1, isNull);
    });
  });

  group('mismatchDetected (crypto-level simulation)', () {
    test('failed decrypt produces empty text and decryptFailed flag', () async {
      const roomCode = 'WOLF-1234';
      final keyA = await deriveKey(phrase: 'xerxes', roomCode: roomCode);
      final keyB = await deriveKey(phrase: 'Xerxes', roomCode: roomCode);

      final encrypted = await encryptMessage(plaintext: 'hello', key: keyA);
      final result = await decryptMessage(
        ciphertextBase64: encrypted.ciphertext,
        nonceBase64: encrypted.nonce,
        key: keyB,
      );

      // Simulates what ChatClient does: on null → mismatchDetected = true, text = ''
      expect(result, isNull);
      // ChatClient would set: ChatMessage(text: '', decryptFailed: true)
    });

    test('successful round-trip leaves no mismatch', () async {
      const roomCode = 'BEAR-1111';
      final key = await deriveKey(phrase: 'same', roomCode: roomCode);
      final encrypted = await encryptMessage(plaintext: 'works', key: key);
      final result = await decryptMessage(
        ciphertextBase64: encrypted.ciphertext,
        nonceBase64: encrypted.nonce,
        key: key,
      );
      expect(result, 'works');
      // ChatClient would leave mismatchDetected = false
    });

    test('buffer + mismatch: all buffered messages fail', () async {
      const roomCode = 'FOX-2222';
      final peerKey = await deriveKey(phrase: 'correct', roomCode: roomCode);
      final enc1 = await encryptMessage(plaintext: 'msg1', key: peerKey);
      final enc2 = await encryptMessage(plaintext: 'msg2', key: peerKey);

      final wrongKey = await deriveKey(phrase: 'wrong', roomCode: roomCode);
      final d1 = await decryptMessage(ciphertextBase64: enc1.ciphertext, nonceBase64: enc1.nonce, key: wrongKey);
      final d2 = await decryptMessage(ciphertextBase64: enc2.ciphertext, nonceBase64: enc2.nonce, key: wrongKey);
      expect(d1, isNull);
      expect(d2, isNull);
    });
  });
}
