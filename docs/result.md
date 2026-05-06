# Last Task Result

## Task
Phase 2 / Task 8b — UX polish: SystemMessage alignment + role-based bubble labels.

## Branch
task/chat-ux-polish

## Commit
feat: chat ux polish — left-align multiline system messages, role/nickname bubble labels

## What Was Done

### SystemMessage alignment (Part B)
- Single-line messages remain centered (backward-compatible with existing toasts)
- Multi-line messages (containing `\n`) are now left-aligned with `TextAlign.start` and horizontal padding — no more center-jagged wraps

### ChatClient state (Part C)
- Added `isHost` (bool?) and `localNickname` (String?) fields
- `createRoom()` sets `isHost=true` + nickname; `joinRoom()` sets `isHost=false` + nickname
- `close()` resets both to null
- Nickname is trimmed; blank strings become null

### Bubble labels (Part D)
- Replaced `msg.fromSelf ? 'YOU' : 'PEER'` with `_labelFor(msg)` helper
- Self messages: show `localNickname` if set, else role (`host`/`peer`)
- Remote messages: show opposite role (`peer` if host, `host` if peer)
- Removed `.toUpperCase()` from MessageBubble — labels render lowercase
- Nicknames truncated at 24 chars

### Wiring (Part E)
- RoomSetupScreen passes `_nicknameController.text` into `createRoom()`
- JoinRoomScreen passes `_nicknameController.text` into `joinRoom()`

### Tests (Part F)
- flutter analyze: no issues
- flutter test: 36/36 pass (was 27)
- npm test: 35/35 pass (unchanged)

### Verification
- `git diff --name-only main..HEAD`: 7 files (no server, no protocol changes)
- No new dependencies, no crypto

## Status
Done

## Notes
- What's next: live verification by Owner, then Task 9 (Argon2id + XChaCha20-Poly1305)
- Remote peer nickname propagation is deferred — remote bubble always shows role fallback for now
