// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cryptography/cryptography.dart';

void main() async {
  final keyFile = File('tools/keys/activation.private.key');

  if (keyFile.existsSync()) {
    print('ERROR: ${keyFile.path} already exists.');
    print('Delete it manually if you want a new keypair.');
    exit(1);
  }

  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final privateBytes = await keyPair.extractPrivateKeyBytes();
  final publicKey = await keyPair.extractPublicKey();

  // Write private key as hex to file.
  keyFile.parent.createSync(recursive: true);
  final hex = privateBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  keyFile.writeAsStringSync('$hex\n');

  // Print public key as Dart array literal.
  final pubBytes = publicKey.bytes;
  final buffer = StringBuffer('const List<int> activationPublicKey = <int>[\n');
  for (var i = 0; i < pubBytes.length; i += 8) {
    final end = (i + 8 > pubBytes.length) ? pubBytes.length : i + 8;
    final row = pubBytes.sublist(i, end).join(', ');
    buffer.write('  $row,\n');
  }
  buffer.write('];');

  print(buffer.toString());
}
