# Last Task Result

## Task
Phase 2 / Task 10 — Decrypt-failure UX + mismatch composer lock.

## Branch
task/decrypt-failure-ux

## Commit
feat: decrypt-failure ux — mismatch warning + composer lock

## What Was Done

- **ChatClient**: Added `_mismatchDetected` flag (one-way, set on first decrypt failure, cleared by `close()`). Failed decrypts now emit `ChatMessage(text: '', decryptFailed: true)` — no raw ciphertext in UI.
- **MessageBubble**: Added `decryptFailed` param. When true: muted background, muted border, italic "unreadable" text — ignores the `text` prop.
- **ChatScreen**:
  - Composer disabled when `mismatchDetected` (same as `_peerLeft`)
  - Mismatch SystemMessage warning appears above password-mode message
  - Hint text precedence: room closed > phrase mismatch > type the phrase > message
  - Tap-anywhere-to-exit activates on mismatch
  - Fixed stale copy: removed "(encryption arrives in task 9)", open-mode banner now "[open mode — messages are sent in plaintext]"
  - Mode-aware micro-text: "ENCRYPTED" / "PLAINTEXT" (top-bar + footer)
- **Tests**: ChatScreen widget tests (7), mismatchDetected crypto-level tests (3), updated room_setup assertions

## Status
Done

## Notes
- `flutter analyze`: no issues
- `flutter test`: 69 tests (up from 59 in Task 9)
- `npm test`: 39 tests (unchanged — no server changes)
- `git diff --name-only main..HEAD`: chat_client.dart, chat_screen.dart, message_bubble.dart, chat_client_test.dart, chat_screen_test.dart (new), room_setup_test.dart, chat_ux_polish_test.dart
- Stale "encryption arrives in task 9" and hardcoded "PLAINTEXT" copy: found and fixed in both chat_screen.dart and test assertions
