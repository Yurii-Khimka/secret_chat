# Plan

_Updated by the Tech Lead chat before each task._

## Status

**Active task:** Phase 2 / Task 9 — **End-to-end encryption: Argon2id KDF + XChaCha20-Poly1305 messages**.

This is the crypto core of the password feature. After Task 9, password-mode rooms actually encrypt messages — matched phrases produce readable chat, mismatched phrases produce un-readable output. Decryption-failure UX polish is **Task 10**; for Task 9 we only need to ensure decrypt-failure does not crash and produces *some* output that subsequent tasks can refine.

## Context

### The model (recap — read carefully)

Password is the **first message both users type**. It never leaves the device. Locally, each client runs the phrase through Argon2id to derive a 32-byte symmetric key, then encrypts every subsequent message with XChaCha20-Poly1305. Server only relays ciphertext; it cannot verify a "match." Match is implicit: same phrase → same key → ciphertext decrypts. Mismatch → recipient sees garbled output.

Both clients agree on the phrase **out of band**. Case-sensitive. The first message a user types becomes their phrase locally. The first message they receive is decrypted with their own derived key.

### Open mode is unchanged

Rooms with `password_mode: false` continue to send plaintext `msg.text` exactly as today. Task 9 only changes behavior when `chatClient.passwordMode == true`.

### Library choice

Use [`cryptography`](https://pub.dev/packages/cryptography) (Gohilla) — pure-Dart, includes both `Argon2id` and `Xchacha20.poly1305Aead()`. No FFI plugin required for Task 9. If Argon2 turns out to be unacceptably slow on iPhone (>2s for default OWASP params), report back in `result.md` and we'll evaluate `cryptography_flutter` or lower the work factor in a follow-up.

### KDF parameters

Argon2id with **OWASP "second recommended" profile** for password-derivation:
- `memorySize`: 19456 (≈ 19 MiB, in KiB units per the package API)
- `parallelism`: 1
- `iterations`: 2
- `hashLength`: 32 bytes

If that proves too slow on the simulator, fall back to `memorySize: 12288` (12 MiB), `iterations: 3`. Note the actual choice in `result.md`.

### Salt

Salt is **deterministic from the room code** so both clients derive the same key without any handshake:

```
salt = SHA-256(utf8(roomCode))[0 .. 16)   // first 16 bytes
```

This is acceptable because the salt's job is uniqueness across rooms (which the room code guarantees), not secrecy. The phrase is the secret.

### Wire format for encrypted messages

Per-room shape, decided by client based on `passwordMode`:

- **Open mode** (`password_mode == false`):
  ```json
  { "type": "msg", "text": "hello" }
  ```
  Unchanged from today.

- **Password mode** (`password_mode == true`):
  ```json
  { "type": "msg", "ciphertext": "<base64>", "nonce": "<base64>" }
  ```
  No `text` field. The Poly1305 MAC is appended to the ciphertext bytes before base64-encoding (i.e. the standard AEAD output is `ciphertext || tag`).

Both clients must use the same XChaCha20 nonce length (24 bytes / 192 bits, randomly generated per message).

## Read First

- [CLAUDE.md](../CLAUDE.md)
- [docs/result.md](result.md) — Task 8c closeout
- [docs/sessions.md](sessions.md)
- [docs/changelog.md](changelog.md)
- [pubspec.yaml](../pubspec.yaml) — to add the `cryptography` dependency
- [lib/network/chat_client.dart](../lib/network/chat_client.dart) — central wiring; encryption state + send/receive paths live here
- [lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart) — first-message-as-phrase hint for the local user
- [server/src/protocol.js](../server/src/protocol.js) — `msg` shape + frame size
- [server/src/ws.js](../server/src/ws.js) — `msg` validation
- [server/src/rooms.js](../server/src/rooms.js) — `passwordMode` already stored on room

## Current Task

### Part A — Branching

1. Switch to `main`. Merge `task/phrase-message-wrap` into `main` (no fast-forward).
2. Delete the local `task/phrase-message-wrap` branch.
3. Branch off `main` as `task/e2e-encryption`.

### Part B — Add `cryptography` dependency

Add `cryptography: ^2.7.0` (or current latest stable) to [pubspec.yaml](../pubspec.yaml) under `dependencies`. Run `flutter pub get`. Do not pin to a non-latest version unless there's a known incompatibility.

### Part C — `lib/network/crypto.dart` (new file)

Encapsulate all crypto primitives in one module so the rest of the codebase doesn't import `cryptography` directly. Public API:

```dart
/// Derives a 32-byte key from `phrase` using Argon2id, salted with SHA-256(roomCode)[0..16).
Future<Uint8List> deriveKey({required String phrase, required String roomCode});

/// Encrypts plaintext with XChaCha20-Poly1305. Returns (nonceBase64, ciphertextBase64).
/// `ciphertextBase64` is base64(ciphertextBytes || tag).
Future<({String nonce, String ciphertext})> encryptMessage({
  required String plaintext,
  required Uint8List key,
});

/// Decrypts. Returns null on auth-tag mismatch (wrong key, tampered ciphertext, or malformed input).
Future<String?> decryptMessage({
  required String ciphertextBase64,
  required String nonceBase64,
  required Uint8List key,
});
```

Notes:
- Use `Argon2id(memory: 19456, parallelism: 1, iterations: 2, hashLength: 32)`.
- Use `Xchacha20.poly1305Aead()` for the cipher.
- `decryptMessage` must catch `SecretBoxAuthenticationError` (or whatever the package raises) and return `null` rather than re-throw. Never log the ciphertext or any partial plaintext.
- All bytes-to-string conversion is base64 standard (not URL-safe).

Add unit tests in [test/network/crypto_test.dart](../test/network/crypto_test.dart):
- `deriveKey` is deterministic for same (phrase, roomCode).
- Different phrases → different keys.
- Different roomCodes → different keys (same phrase).
- Encrypt/decrypt round-trip with the same key recovers plaintext.
- Decrypt with a wrong key returns `null` (no exception thrown).
- Decrypt with malformed base64 returns `null`.
- Nonce is 24 bytes (after base64-decode).

### Part D — `ChatClient` encryption state ([lib/network/chat_client.dart](../lib/network/chat_client.dart))

Add private state:

- `Uint8List? _key` — derived from local phrase, null until set
- `bool get hasKey => _key != null;` — public getter (used by ChatScreen for UX hints in Task 10; expose it now)
- `final List<_PendingCiphertext> _pendingDecrypt = [];` — buffered incoming ciphertexts that arrived before `_key` was set

Reset `_key = null` and clear `_pendingDecrypt` in `close()`.

#### Sending a message (`sendMessage(String text)`):

1. **Open mode**: send `{type: msg, text}` as today.
2. **Password mode**, `_key == null`: this is the local user's phrase. Derive `_key = await deriveKey(phrase: text, roomCode: roomCode!)`, then encrypt `text` with the new key and send `{type: msg, ciphertext, nonce}`. The phrase IS sent as a (now-encrypted) message — peer with matching phrase will see it; peer with mismatched phrase will see garbled output.
3. **Password mode**, `_key != null`: encrypt `text` with `_key` and send.

After step 2, `notifyListeners()` so the UI can reflect "key set" if it cares.

#### Receiving a message:

When a `msg` frame arrives:

1. **Open mode** + frame has `text`: emit `ChatMessage(fromSelf: false, text: text)` as today.
2. **Open mode** + frame has `ciphertext`: protocol violation. Log a lifecycle-level warning (no contents) and drop the frame. Do not crash.
3. **Password mode** + frame has `text`: protocol violation. Drop.
4. **Password mode** + frame has `ciphertext`, `_key == null`: append to `_pendingDecrypt`. Do not emit a message yet.
5. **Password mode** + frame has `ciphertext`, `_key != null`: attempt decrypt. On success → emit `ChatMessage(fromSelf: false, text: decrypted)`. On failure → emit `ChatMessage(fromSelf: false, text: '<<' + ciphertextBase64 + '>>', decryptFailed: true)`.

Add a `bool decryptFailed` flag (default false) to `ChatMessage`. Task 10 will use it for styling; for Task 9 the `<<...>>` text is good enough to render.

After `_key` is set (in send-path step 2), drain `_pendingDecrypt` in order, attempting decrypt for each. Append the resulting `ChatMessage`s in original-arrival order. **Insert them BEFORE the local user's just-sent first message** — i.e. anything the peer sent before the local user typed their phrase should appear above the local first message in the chat history. Implementation hint: drain `_pendingDecrypt` first, append the local message last.

### Part E — Self-display of own first message in password mode

The local user's own first message (the phrase) renders in their chat as a normal "you" bubble showing the typed plaintext. No special masking. We're not trying to hide the phrase from the user who typed it. (UX consideration: phrase visible on screen, like any other message. If they want to hide it after, that's a future feature.)

### Part F — ChatScreen first-message hint

In [lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart), when password mode is on AND `chatClient.hasKey == false`, the message input's placeholder/hint text changes from the default to:

```
type the phrase…
```

(lowercase, single line, replacing whatever the current placeholder says). Once `hasKey` becomes true, the placeholder reverts to the default.

This is the only ChatScreen change for Task 9. The phrase-mode `SystemMessage` from Task 8 stays as-is.

### Part G — Server changes

In [server/src/ws.js](../server/src/ws.js)'s `msg` handler:

1. Validate the `msg` frame:
   - Must have **exactly one** of `text` or (`ciphertext` + `nonce`). Reject otherwise with `error` code `bad_request`, reason `"invalid msg shape"`.
   - `text`, `ciphertext`, `nonce` must each be non-empty strings if present. Length cap: 4096 chars each (well below the 16 KB frame cap).
2. Cross-check against room's `passwordMode`:
   - If `passwordMode == true` and frame has `text` → reject with `bad_request`, reason `"plaintext not allowed in password room"`.
   - If `passwordMode == false` and frame has `ciphertext` → reject with `bad_request`, reason `"ciphertext not allowed in open room"`.
3. Relay the frame to the peer **verbatim** (do not re-shape, do not log contents — per the HARD RULE at the top of `ws.js`).

Add server tests in `server/test/`:
- Open room: `msg` with `text` relays. `msg` with `ciphertext` rejected.
- Password room: `msg` with `ciphertext` + `nonce` relays. `msg` with `text` rejected.
- Both rooms: `msg` with neither / both fields rejected.
- Length-cap test: `text` of length 4097 → rejected.

### Part H — Flutter integration tests

In [test/network/chat_client_test.dart](../test/network/chat_client_test.dart):

- Open-mode end-to-end: send `hello` → outgoing payload has `text: hello`, no ciphertext.
- Password-mode first message: send `secret` → outgoing payload has `ciphertext` + `nonce`, no `text`. `chatClient.hasKey` becomes `true`.
- Password-mode subsequent messages: encrypted with the same key (decrypting with a fresh key derived from the same phrase + room code recovers the plaintext).
- Round-trip with matched phrases: peer A sends `hello` (encrypted with key derived from phrase `xerxes`); peer B (same phrase) decrypts and sees `hello`.
- Mismatched phrases: peer A uses `xerxes`, peer B uses `Xerxes` — peer B receives a `ChatMessage` with `decryptFailed: true` and text starting with `<<` and ending with `>>`.
- Buffering: peer sends 2 ciphertext messages; local user has not typed phrase yet → no `ChatMessage` emitted yet. Local types phrase (matching) → buffered messages decrypt and appear above the local first message.
- Buffering with mismatch: same as above but local types a wrong phrase → buffered messages emit with `decryptFailed: true`.

### Part I — `flutter analyze`, `flutter test`, `npm test`

All clean. New tests grow both flutter and npm counts. Confirm in result.md.

### Part J — Commit

One commit:

`feat: e2e encryption — argon2id key derivation + xchacha20-poly1305 messages`

### Part K — Output (in your response and at the top of `result.md`)

- Confirm `flutter analyze` clean.
- `flutter test` count vs. Task 8c's 36.
- `npm test` count vs. 35.
- `git diff --name-only main..HEAD` — expect new `lib/network/crypto.dart`, `test/network/crypto_test.dart`, and changes to `chat_client.dart`, `chat_screen.dart`, `pubspec.yaml`, server `ws.js` + protocol + tests.
- A note on Argon2id measured timing (rough estimate is fine — derive once on the simulator and report the duration). If it exceeded ~2s, mention it; we'll decide together whether to lower work factor.

### Part L — Update docs/result.md, docs/sessions.md, docs/changelog.md

Per CLAUDE.md §4–§6.

## Specs

- Branch: `task/e2e-encryption` (off `main`, after merging Task 8c).
- One commit at the end.
- Pure-Dart `cryptography` package only. No native plugin in this task.
- Argon2id (m=19456, t=2, p=1, len=32) with fallback to (12288, 3) if unbearably slow.
- Salt = SHA-256(roomCode)[0..16).
- XChaCha20-Poly1305, 24-byte random nonce per message, base64-encoded ciphertext (with appended tag) and nonce on the wire.

## Do NOT

- Do not log phrases, keys, plaintexts, ciphertexts, or any portion thereof — anywhere. Server `ws.js` already enforces this; respect it on the client side too.
- Do not store the phrase persistently. `_key` is in-memory only and cleared on `close()`.
- Do not implement decryption-failure UX polish (styling, tone, special bubble) — that's Task 10. For Task 9, `<<base64>>` text on a normal bubble is sufficient.
- Do not change the open-mode wire format.
- Do not propagate nicknames over the wire (that's still deferred to a later task).
- Do not push the branch.

## Commit Message

`feat: e2e encryption — argon2id key derivation + xchacha20-poly1305 messages`
