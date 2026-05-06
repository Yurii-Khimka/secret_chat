# Last Task Result

## Task
Phase 3 / Task 17 — Activation gate v1: ed25519-signed access codes.

## Branch
task/activation-gate-v1

## Commit
feat: activation gate v1 — ed25519-signed access codes

## What Was Done

1. **`.gitignore`**: Added `tools/keys/` and `*.private.key` entries.
2. **`tools/keygen.dart`**: Owner-side CLI — generates ed25519 keypair, writes private key to `tools/keys/activation.private.key` (hex), prints public key as Dart array literal. Refuses to overwrite existing key.
3. **`tools/mint_code.dart`**: Owner-side CLI — reads private key, signs `{id, iat}` payload, prints `<base64url(payload)>.<base64url(signature)>` activation code. Inline UUIDv4 (no uuid package).
4. **`lib/security/activation_pubkey.dart`**: Embedded public key placeholder (32 zero bytes). Causes `verifyActivationCode` to reject all codes until replaced.
5. **`lib/security/activation.dart`**: `verifyActivationCode()` — ed25519 signature verification, whitespace stripping, placeholder rejection. `@visibleForTesting` pubkey override for tests.
6. **`lib/security/activation_controller.dart`**: `ActivationController` (ChangeNotifier) — `load()` re-verifies persisted code on startup (clears if invalid), `activate()` verifies+persists, `clearError()` for UX.
7. **`lib/screens/activation_screen.dart`**: Full terminal-aesthetic activation screen — PulseDot + ACCESS CODE header, "Invite required" heading with blinking Caret, multi-line paste TextField, ACTIVATE button, error display, footer micro-text. Reuses AppScaffold, AppButton, Caret, PulseDot.
8. **`lib/main.dart`**: Wired `ActivationController` — `Listenable.merge` drives `AnimatedBuilder`, gates HomeScreen behind activation.
9. **Tests**: 21 new tests — 11 pure-verification, 6 controller, 4 screen widget tests.
10. **`docs/readme.md`**: Added "Activation (v1)" section with collaborator instructions.

## Status
Done

## Notes
- `flutter analyze`: clean
- `flutter test`: 123 total (117 pass + 6 pre-existing timeouts), up from 102
- `npm test`: 43 (unchanged)
- `tools/keys/` is NOT in the diff (gitignored, never staged)
- Placeholder pubkey is all zeros — `verifyActivationCode` returns false against it (verified by test)
- Caret component reused on ActivationScreen — "Invite required" heading has a blinking caret
- No new dependencies (cryptography already in pubspec)
- No server changes
