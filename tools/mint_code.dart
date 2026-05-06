// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

String _generateUuidV4() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));

  // Set version 4.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // Set variant 10xx.
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(List<int> b) => b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();

  return '${hex(bytes.sublist(0, 4))}-${hex(bytes.sublist(4, 6))}-'
      '${hex(bytes.sublist(6, 8))}-${hex(bytes.sublist(8, 10))}-'
      '${hex(bytes.sublist(10, 16))}';
}

void main(List<String> args) async {
  final keyFile = File('tools/keys/activation.private.key');

  if (!keyFile.existsSync()) {
    stderr.writeln('ERROR: ${keyFile.path} not found. Run dart run tools/keygen.dart first.');
    exit(1);
  }

  // Parse --id flag.
  String? customId;
  for (final arg in args) {
    if (arg.startsWith('--id=')) {
      customId = arg.substring(5);
    }
  }

  // Read private key (hex-encoded 32 bytes).
  final hexString = keyFile.readAsStringSync().trim();
  final privateBytes = <int>[];
  for (var i = 0; i < hexString.length; i += 2) {
    privateBytes.add(int.parse(hexString.substring(i, i + 2), radix: 16));
  }

  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPairFromSeed(privateBytes);

  // Build payload.
  final id = customId ?? _generateUuidV4();
  final iat = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final payloadJson = '{"id":"$id","iat":$iat}';
  final payloadBytes = utf8.encode(payloadJson);

  // Sign.
  final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);

  // Encode as base64url.
  final payloadB64 = base64Url.encode(payloadBytes);
  final sigB64 = base64Url.encode(signature.bytes);

  print('$payloadB64.$sigB64');
}
