import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:secret_chat/security/activation.dart';

late List<int> testPublicKeyBytes;

Future<({SimpleKeyPairData keyPair, List<int> publicKeyBytes})> generateTestKeyPair() async {
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final publicKey = await keyPair.extractPublicKey();
  testPublicKeyBytes = publicKey.bytes;
  setActivationPublicKeyForTesting(publicKey.bytes);
  return (keyPair: keyPair as SimpleKeyPairData, publicKeyBytes: publicKey.bytes);
}

Future<String> generateTestActivationCode({SimpleKeyPairData? keyPair}) async {
  final algorithm = Ed25519();

  SimpleKeyPairData kp;
  if (keyPair != null) {
    kp = keyPair;
  } else {
    final result = await generateTestKeyPair();
    kp = result.keyPair;
  }

  final payloadJson = '{"id":"test-id","iat":${DateTime.now().millisecondsSinceEpoch ~/ 1000}}';
  final payloadBytes = utf8.encode(payloadJson);

  final signature = await algorithm.sign(payloadBytes, keyPair: kp);

  final payloadB64 = base64Url.encode(payloadBytes);
  final sigB64 = base64Url.encode(signature.bytes);

  return '$payloadB64.$sigB64';
}
