/// Public key for verifying activation codes.
///
/// Replace the 32-byte placeholder below with your production public key
/// before shipping a release build. Run `dart run tools/keygen.dart` to
/// generate a fresh keypair; paste the printed array into [activationPublicKey].
///
/// The placeholder (all zeros) causes [verifyActivationCode] to reject every
/// code, intentionally locking the app until configured.
const List<int> activationPublicKey = <int>[
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
];
