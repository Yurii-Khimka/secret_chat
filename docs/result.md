# Last Task Result

## Task
Phase 2 / Task 9 — End-to-end encryption: Argon2id KDF + XChaCha20-Poly1305 messages.

## Branch
task/e2e-encryption

## Commit
feat: e2e encryption — argon2id key derivation + xchacha20-poly1305 messages

## What Was Done

Implemented full E2E encryption for password-mode rooms:

- **crypto.dart** (new): `deriveKey()` using Argon2id (m=19456, p=1, t=2, len=32) with SHA-256(roomCode)[0..16) as salt; `encryptMessage()` / `decryptMessage()` using XChaCha20-Poly1305 with 24-byte random nonce per message.
- **ChatClient**: Added `_key`, `hasKey`, `_pendingDecrypt` state. Send path: first message in password mode derives key from phrase, drains pending buffer, encrypts. Receive path: buffers ciphertext until key set, then decrypts. Open mode unchanged.
- **ChatMessage**: Renamed from `IncomingMessage`, added `decryptFailed` flag.
- **protocol.dart**: `MsgMsg` now has `text?`, `ciphertext?`, `nonce?` fields. New `msgTextFrame()` / `msgCipherFrame()` builders replace old `msgFrame()`.
- **ChatScreen**: Hint text shows "type the phrase…" when passwordMode && !hasKey.
- **Server ws.js**: Validates `msg` shape (exactly one of text or ciphertext+nonce), cross-checks against room's passwordMode, enforces 4096-char cap per field. Relays verbatim.
- **Tests**: crypto unit tests (7), chat_client E2E tests (12), updated protocol tests, updated server relay tests.

## Status
Done

## Notes
- `flutter analyze`: no issues
- `flutter test`: 59 tests (up from 36 in Task 8c)
- `npm test`: 39 tests (up from 35)
- Argon2id timing on Mac (pure Dart): ~166ms — well within 2s budget. No need for fallback parameters.
- `cryptography: 2.9.0` installed (latest stable, compatible with ^2.7.0 constraint)
- OWASP "second recommended" Argon2id profile used as specified (m=19456 KiB, t=2, p=1)
