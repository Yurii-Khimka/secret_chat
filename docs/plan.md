# Plan

_Updated by the Tech Lead chat before each task._

## Status

**Active task:** Phase 2 / Task 11 — **Security cleanup: memory wipe on close + lifecycle hardening**.

Project rule from [docs/readme.md](readme.md): _"When the app is closed — everything is deleted."_ Today's `ChatClient.close()` nulls references but does not zero the underlying key bytes, and the WebSocket close path is best-effort. This task makes "everything deleted" a verified contract: the symmetric key bytes are zeroed before being released, all ephemeral state is cleared, the socket is forcibly torn down, and the lifecycle observer covers the cases that actually matter on iOS / Android.

## Context

### What close() does today

[lib/network/chat_client.dart:265-283](../lib/network/chat_client.dart):

```dart
Future<void> close() async {
  final channel = _channel;
  _channel = null;
  _subscription?.cancel();
  _subscription = null;
  _roomCode = null;
  _lastError = null;
  _passwordMode = false;
  _isHost = null;
  _localNickname = null;
  _messages.clear();
  _key = null;             // <-- just drops the reference
  _pendingDecrypt.clear();
  _state = ChatConnectionState.idle;
  try {
    await channel?.sink.close();
  } catch (_) {}
  notifyListeners();
}
```

Gaps (in priority order):

1. **`_key = null` does not zero the bytes.** The `Uint8List` lives on the Dart heap until GC. A heap snapshot taken between `close()` and the next GC cycle still contains the 32 derived bytes. Same for buffered ciphertexts.
2. **`_mismatchDetected` is not reset here** (Task 10 added a reset in close, but verify; if missing, add it).
3. **`_messages.clear()` releases the list backing but the `ChatMessage.text` strings — including any plaintext the user typed and any peer plaintext — remain in heap until GC.** Strings are immutable in Dart, so we cannot zero them. Best we can do: drop the references promptly and document the limit.
4. **`channel?.sink.close()` is awaited but not bounded.** A misbehaving network can hang it. The rest of `close()` already ran, so the visible state is clean, but it leaves a pending future. Add a short timeout.
5. **`paused` lifecycle does NOT close the session** — this was an explicit Task 7b decision (preserve session through backgrounding). Confirm that's still the right call given Task 11's threat model. I am keeping it: backgrounding-then-foregrounding-the-app is a routine UX flow on mobile and breaking the room there would be hostile. We lean on `detached` for cleanup, plus an explicit "leave" gesture.
6. **No app-level guard against returning to a screen after close.** If `close()` runs while ChatScreen is on top (e.g. `detached`), the `_messages.clear()` happens but the ListView may rebuild with stale state. Verify this is harmless (it should be — `_state` flips to `idle` and listeners fire).

### What `crypto.dart` exposes today

`deriveKey()` returns a fresh `Uint8List`. It's the only producer of key bytes. We can zero those bytes when the client is done with them.

### What we cannot do

- **We cannot zero the AES-key copies inside the `cryptography` package.** `SecretKey` and `Argon2id` internals make their own buffers. This is acceptable per the project's threat model (we are not defending against a compromised process with heap access — that's out of scope for a chat app on a phone).
- **We cannot zero `String` plaintexts.** Dart strings are immutable.
- **We are not introducing a native FFI just to call `mlock`/`memset_s`.** Out of scope.

What we *can* do is zero the one buffer we own (`_key`), drop references promptly, document the limits, and add a test that asserts the contract.

## Read First

- [CLAUDE.md](../CLAUDE.md)
- [docs/result.md](result.md) — Task 10 closeout
- [docs/sessions.md](sessions.md) — locked Phase 2 constraints (especially "Phrase / key — never stored, never exposed")
- [docs/readme.md](readme.md) — "When the app is closed — everything is deleted"
- [docs/changelog.md](changelog.md)
- [lib/main.dart](../lib/main.dart) — app lifecycle observer
- [lib/network/chat_client.dart](../lib/network/chat_client.dart) — `close()`, `_key`, `_pendingDecrypt`
- [lib/network/crypto.dart](../lib/network/crypto.dart) — key derivation
- [test/network/chat_client_test.dart](../test/network/chat_client_test.dart)

## Current Task

### Part A — Branching

1. Switch to `main`. Merge `task/decrypt-failure-ux` into `main` (no fast-forward).
2. Delete the local `task/decrypt-failure-ux` branch.
3. Branch off `main` as `task/security-cleanup`.

### Part B — Zero the key bytes on `close()`

In [lib/network/chat_client.dart](../lib/network/chat_client.dart):

1. Before `_key = null`, if `_key != null`, fill it with zeros:
   ```dart
   final k = _key;
   if (k != null) {
     for (var i = 0; i < k.length; i++) {
       k[i] = 0;
     }
   }
   _key = null;
   ```
   The byte loop is intentional — `Uint8List.fillRange(0, k.length, 0)` is equivalent and acceptable; pick whichever you prefer for readability. **Do not** simply `_key = Uint8List(0)` — that allocates a new buffer and leaves the old one untouched.
2. Also zero each buffered ciphertext. `_PendingCiphertext` holds `String`s (`ciphertext`, `nonce`) which we cannot zero, but we can clear the list before the iteration so references drop ASAP. Replace `_pendingDecrypt.clear()` placement: clear it as the *first* mutation in `close()`, not in the middle.

### Part C — Bounded socket teardown

In `close()`:

1. Wrap `channel?.sink.close()` in a `Future.any` race against a 1-second timer. Whichever completes first wins. Reason: a hung sink should not delay the UI from observing the cleared state.
   ```dart
   try {
     await Future.any([
       channel?.sink.close() ?? Future.value(),
       Future.delayed(const Duration(seconds: 1)),
     ]);
   } catch (_) {}
   ```
2. The existing `try/catch` stays — sink close can throw on already-closed channels, that's fine.

### Part D — Reset `_mismatchDetected` defensively

Confirm Task 10's `close()` already resets `_mismatchDetected = false`. If not, add it. (This is a verification step — the implementation may already be correct.)

### Part E — `_messages` clearing — document the limit

`ChatMessage` instances hold `String text` references. We cannot zero strings. Add a single-line comment in `close()` above `_messages.clear()`:

```dart
// Strings are immutable; clearing the list drops references but does not zero memory.
```

This is the only comment we add. Do not annotate the rest of close().

### Part F — Idempotent close

`close()` should be safe to call twice (e.g. `detached` lifecycle + an explicit Home navigation racing). Today, the second call would: encounter `_channel == null`, the `_key` zero-loop skips because `_key == null`, list clears are no-ops, and `notifyListeners()` fires harmlessly. That is acceptable as-is. **Add a test** to lock the behavior in (Part I).

### Part G — Lifecycle: keep `detached`-only

In [lib/main.dart](../lib/main.dart):

- **No change to lifecycle policy.** `paused` does not close. `detached` does. This was deliberately decided in Task 7b and remains correct: `paused` fires for routine backgrounding (notification shade, app-switcher, lock screen) and breaking the chat there is hostile UX.
- Add a short comment above `didChangeAppLifecycleState` explaining the policy if not already adequate. Keep the existing comment if it's clear; don't expand for the sake of expansion.

### Part H — Crypto module: defensive zeroing helper

In [lib/network/crypto.dart](../lib/network/crypto.dart), add a small public helper:

```dart
/// Zeros [bytes] in place. Safe to call on a null reference.
void zeroBytes(Uint8List? bytes) {
  if (bytes == null) return;
  bytes.fillRange(0, bytes.length, 0);
}
```

ChatClient uses this in `close()` instead of an inline loop. Reason: keeps all crypto-adjacent primitives in one module, matches the existing convention.

Add unit tests in [test/network/crypto_test.dart](../test/network/crypto_test.dart):

- `zeroBytes(null)` is a no-op (does not throw).
- `zeroBytes(Uint8List)` sets every byte to 0.
- `zeroBytes` on the output of `deriveKey` zeros the key (round-trip: derive → zero → bytes are all 0).

### Part I — Tests in `chat_client_test.dart`

In [test/network/chat_client_test.dart](../test/network/chat_client_test.dart), add a new group `close() — security cleanup`:

- After `close()`, `chatClient.hasKey == false`, `chatClient.mismatchDetected == false`, `chatClient.roomCode == null`, `chatClient.localNickname == null`, `chatClient.isHost == null`, `chatClient.passwordMode == false`, `chatClient.messages.isEmpty == true`, `chatClient.state == ChatConnectionState.idle`.
- Calling `close()` twice in a row does not throw and produces the same final state.
- **Key-zeroing test (the load-bearing one):** Inject or expose a way to capture the `Uint8List` reference held by `_key` *before* close(). Options:
  1. Add a `@visibleForTesting` getter `Uint8List? get debugKeyBytes => _key;` to ChatClient. Capture the reference, run close(), assert every byte is 0.
  2. Or: refactor `_key` setter to call `zeroBytes` on the previous value when overwritten and test that path. This is more invasive — pick option 1.
  Use `@visibleForTesting` annotation from `package:meta`. The getter exists for tests only.
- Bounded teardown test: not feasible without a fake WebSocketChannel that hangs `sink.close`. Skip — covered by code review and the existing `close()` integration test count.

### Part J — `flutter analyze`, `flutter test`, `npm test`

All clean. New flutter test count grows from 69. Server tests stay at 39 (no server changes).

### Part K — Commit

One commit:

`chore: security cleanup — zero key bytes on close + bounded socket teardown`

### Part L — Output (in your response and at the top of `result.md`)

- Confirm `flutter analyze` clean.
- `flutter test` count vs. Task 10's 69.
- `npm test` count (expect unchanged: 39).
- `git diff --name-only main..HEAD` — expect changes in: `chat_client.dart`, `crypto.dart`, `chat_client_test.dart`, `crypto_test.dart`.
- A note confirming the key-zeroing test passes (i.e. captured `Uint8List` is all zero after `close()`).
- A note on the `paused`-lifecycle policy: confirm the existing `detached`-only branch is intentional and unchanged.

### Part M — Update docs/result.md, docs/sessions.md, docs/changelog.md

Per CLAUDE.md §4–§6.

In sessions.md, tick:
- [x] Session cleanup on app close (memory wipe)

Leave "Verify zero server-side logging" unchecked — that is the next task.

Note in sessions.md that "Key verification handshake between peers" is **superseded by Task 10's implicit-mismatch model** (decryption failure ⇒ mismatch warning + composer lock). Mark it `[~]` or add a one-line comment crossing it out — do not delete.

## Specs

- Branch: `task/security-cleanup` (off `main`, after merging Task 10).
- One commit at the end.
- No new dependencies.
- No protocol or server changes.
- No new components, screens, or tokens.
- No native FFI.

## Do NOT

- Do not log key bytes, plaintexts, ciphertexts, or any portion thereof — the existing rules still hold.
- Do not change lifecycle policy (paused stays a no-op).
- Do not introduce a native crypto plugin.
- Do not zero memory you don't own — `cryptography` package internals are out of scope.
- Do not add a "are you sure you want to leave" prompt — close is silent, immediate, total.
- Do not push the branch.

## Commit Message

`chore: security cleanup — zero key bytes on close + bounded socket teardown`
