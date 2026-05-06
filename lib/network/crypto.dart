import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Derives a 32-byte key from [phrase] using Argon2id, salted with SHA-256(roomCode)[0..16).
Future<Uint8List> deriveKey({required String phrase, required String roomCode}) async {
  final sha256 = Sha256();
  final roomHash = await sha256.hash(utf8.encode(roomCode));
  final salt = roomHash.bytes.sublist(0, 16);

  final argon2id = Argon2id(
    memory: 19456,
    parallelism: 1,
    iterations: 2,
    hashLength: 32,
  );

  final result = await argon2id.deriveKey(
    secretKey: SecretKey(utf8.encode(phrase)),
    nonce: salt,
  );

  return Uint8List.fromList(await result.extractBytes());
}

/// Encrypts plaintext with XChaCha20-Poly1305. Returns (nonce, ciphertext) as base64.
/// ciphertext is base64(ciphertextBytes || tag).
Future<({String nonce, String ciphertext})> encryptMessage({
  required String plaintext,
  required Uint8List key,
}) async {
  final cipher = Xchacha20.poly1305Aead();
  final secretKey = SecretKey(key);
  final secretBox = await cipher.encryptString(
    plaintext,
    secretKey: secretKey,
  );

  // Combine ciphertext + MAC tag (standard AEAD output)
  final combined = Uint8List.fromList([...secretBox.cipherText, ...secretBox.mac.bytes]);

  return (
    nonce: base64.encode(secretBox.nonce),
    ciphertext: base64.encode(combined),
  );
}

/// Zeros [bytes] in place. Safe to call on a null reference.
void zeroBytes(Uint8List? bytes) {
  if (bytes == null) return;
  bytes.fillRange(0, bytes.length, 0);
}

/// Decrypts. Returns null on auth-tag mismatch (wrong key, tampered ciphertext, or malformed input).
Future<String?> decryptMessage({
  required String ciphertextBase64,
  required String nonceBase64,
  required Uint8List key,
}) async {
  try {
    final combined = base64.decode(ciphertextBase64);
    final nonce = base64.decode(nonceBase64);

    if (combined.length < 16) return null;
    if (nonce.length != 24) return null;

    final cipherText = combined.sublist(0, combined.length - 16);
    final mac = Mac(combined.sublist(combined.length - 16));

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final cipher = Xchacha20.poly1305Aead();
    final secretKey = SecretKey(key);
    final decrypted = await cipher.decrypt(secretBox, secretKey: secretKey);

    return utf8.decode(decrypted);
  } catch (_) {
    return null;
  }
}
