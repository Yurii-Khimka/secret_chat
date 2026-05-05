# Last Task Result

## Task
Task 7 — Flutter WebSocket client wired to real server (Phase 2). Closed out by Task 7b (UX gaps) and Task 7c (live verification).

## Branch
task/flutter-network-client

## Commit
docs: close out task 7 — owner-verified J.3–J.7 pass

## What Was Done

### UX changes (Task 7b)

| File | Change |
|------|--------|
| `lib/screens/join_room_screen.dart` | Added `// password gate arrives in task 8` helper text below PASSWORD field (muted color) |
| `lib/main.dart` | Lifecycle: only `detached` triggers close (removed `paused`) |
| `lib/screens/chat_screen.dart` | Added `[plaintext — encryption arrives in task 9]` warning banner above message list |
| `lib/components/system_message.dart` | Extended with `SystemMessageTone` enum (muted/warning) — reused, not duplicated |

### SystemMessage extension
`lib/components/system_message.dart` — added `tone` parameter with `SystemMessageTone.muted` (default, backward compatible) and `SystemMessageTone.warning` (uses `palette.warning` color). No new component created.

### Owner-verified live testing (Task 7c)
The Owner manually executed J.1–J.7 against a real iPhone 17 simulator + running Node server + wscat. CocoaPods was installed to support iOS simulator builds. All steps passed.

### J.1–J.7 Verification table

| Step | Action | Result | Observation |
|------|--------|--------|-------------|
| J.1 | `cd server && npm run dev` | PASS | server listening on http://127.0.0.1:3000 |
| J.2 | `flutter run` on simulator | PASS | app launched on iPhone 17 simulator after CocoaPods install |
| J.3 | Tap CREATE ROOM | PASS | CREATE ROOM produced a unique WORD-NNNN code on each tap |
| J.4 | wscat join_room | PASS | wscat join_room -> simulator auto-navigated to ChatScreen with [plaintext — encryption arrives in task 9] banner visible |
| J.5 | Bidirectional messages | PASS | messages flowed both directions (sim -> wscat and wscat -> sim) |
| J.6 | Close wscat -> peer_left | PASS | closing wscat showed [peer disconnected — room closed] and disabled the composer |
| J.7 | Reverse direction | PASS | reverse direction worked (app joined a wscat-created room, chat functioned) |

**Bonus:** Backgrounding the app for ~5s -> chat session survives (validates detached-only lifecycle fix). PASS.

### flutter analyze
No issues found.

### flutter test — 19/19 pass

### npm test — 29/29 pass

## Status
Done

## Notes
- `ChatClient` follows the same `ChangeNotifier` injection pattern as `ThemeController` — passed through constructors, no DI framework.
- RoomCreatedScreen auto-navigates when `peer_joined` arrives (no manual "Open Chat" button).
- ChatScreen shows "PLAINTEXT" indicator + warning banner since there's no crypto yet.
- The PASSWORD field on JoinRoomScreen is visible and typeable but not wired. Helper text and a `// TODO(task-8): wire password to Argon2` code comment mark the integration point.
- App lifecycle: only `detached` triggers `chatClient.close()`; `paused` (backgrounding) preserves the session — verified manually.
