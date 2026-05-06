# Last Task Result

## Task
Phase 2 / Task 11 — Security cleanup: memory wipe on close + lifecycle hardening.

## Branch
task/security-cleanup

## Commit
chore: security cleanup — zero key bytes on close + bounded socket teardown

## What Was Done

- **crypto.dart**: Added `zeroBytes(Uint8List?)` helper — fills buffer with zeros, null-safe.
- **ChatClient.close()**:
  - `_pendingDecrypt.clear()` moved to first mutation (drop cipher references ASAP)
  - `zeroBytes(_key)` called before `_key = null` — zeroes the 32-byte key buffer
  - Socket teardown bounded to 1s via `Future.any` — hung sink can't block UI
  - Comment added above `_messages.clear()` documenting immutable-string limit
  - `_mismatchDetected = false` confirmed present (Task 10 added it)
- **ChatClient.debugKeyBytes**: `@visibleForTesting` getter to verify zeroing in tests
- **Lifecycle**: `detached`-only policy verified unchanged in main.dart (comment already adequate)
- **Tests**: `zeroBytes` unit tests (3), `close()` security tests (3)

## Status
Done

## Notes
- `flutter analyze`: no issues
- `flutter test`: 75 tests (up from 69 in Task 10)
- `npm test`: 39 tests (unchanged — no server changes)
- Key-zeroing test confirms: derived key bytes are all zero after `zeroBytes()` call
- `paused` lifecycle intentionally does NOT close — routine backgrounding preserves session
- Dart strings are immutable — we cannot zero plaintext in memory, only drop references. Documented.
