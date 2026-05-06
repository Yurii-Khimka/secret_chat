import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import 'activation_pubkey.dart';

List<int>? _testPublicKeyOverride;

@visibleForTesting
void setActivationPublicKeyForTesting(List<int>? bytes) {
  _testPublicKeyOverride = bytes;
}

List<int> _activeKey() => _testPublicKeyOverride ?? activationPublicKey;

/// Verifies an activation code against the embedded public key.
/// Returns false on any error (malformed, wrong-length signature, bad signature,
/// placeholder pubkey). Does not throw.
Future<bool> verifyActivationCode(String code) async {
  try {
    final cleaned = code.replaceAll(RegExp(r'\s'), '');
    if (cleaned.isEmpty) return false;

    // Reject if pubkey is all zeros (placeholder).
    final key = _activeKey();
    if (key.length != 32 || key.every((b) => b == 0)) return false;

    // Split on first dot only.
    final dotIndex = cleaned.indexOf('.');
    if (dotIndex < 0 || dotIndex == 0 || dotIndex == cleaned.length - 1) {
      return false;
    }

    final payloadB64 = cleaned.substring(0, dotIndex);
    final sigB64 = cleaned.substring(dotIndex + 1);

    // Decode base64url (tolerate missing padding).
    final payloadBytes = base64Url.decode(base64Url.normalize(payloadB64));
    final sigBytes = base64Url.decode(base64Url.normalize(sigB64));

    // Signature must be exactly 64 bytes.
    if (sigBytes.length != 64) return false;

    final publicKey = SimplePublicKey(key, type: KeyPairType.ed25519);
    final signature = Signature(sigBytes, publicKey: publicKey);

    final algorithm = Ed25519();
    final isValid = await algorithm.verify(payloadBytes, signature: signature);

    return isValid;
  } catch (_) {
    return false;
  }
}
