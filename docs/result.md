# Last Task Result

## Task
Phase 3 / Task 16 — UI polish pass: 5 fidelity fixes from the audit.

## Branch
task/ui-polish-pass-1

## Commit
feat: ui polish — blinking caret, line height, code slot hints, char counter

## What Was Done

1. **Caret component** (`lib/components/caret.dart`): blinking block cursor, 530ms cycle via `Timer.periodic`, accent-colored by default.
2. **HomeScreen hero caret**: "No trace" line now ends with a blinking `Caret` widget. Refactored from `Text.rich` to `Column` + `Row` to position the caret flush after the text.
3. **DiagCard line height**: overridden locally from 1.6 to 1.9 in `_DiagRow` (home_screen.dart). Global `AppTypography.mono` unchanged.
4. **Code slot empty placeholder**: empty code input slots on JoinRoomScreen now show `_` as hint text (fontSize 22, fontWeight w400, textMuted color).
5. **Character counter**: ChatScreen footer right text now shows `N / 4096` when composing. Turns warning color above 3500 chars. Priority: `_peerLeft` > `mismatchDetected` > counter > `TAP TO TYPE`.
6. **Step copy**: RoomSetup step 03 changed from "Agree on a shared phrase out of band" to "Agree on a shared phrase".

## Rejection Ledger

The following 7 audit items were explicitly rejected by the Tech Lead. Do not re-propose in future tasks without a fresh decision:

- **Chat header `CONNECTED`/`DISCONNECTED` → `ENCRYPTED`** (audit High #1): rejected. Peer-presence is useful information; "ENCRYPTED" is a tautology in password mode and a lie in open mode. Keep the existing label.
- **Chat header sub-row `ENCRYPTED`/`PLAINTEXT` → `AES-256-GCM`** (audit High #2): rejected. We use XChaCha20-Poly1305, not AES-GCM. The design's literal label is factually wrong for our cipher. Our `ENCRYPTED`/`PLAINTEXT` is accurate and mode-aware.
- **Chat footer `ENCRYPTED`/`PLAINTEXT` → `AES-256-GCM`** (audit Medium #3): same reason.
- **RoomSetup step 03 "phrase" → "password"** (audit Medium #5 first half): rejected. Locked Phase 2 constraint (sessions.md): terminology is "phrase," not "password."
- **Restore "set a nickname and a password" sentence on RoomSetup** (audit Medium #6): rejected. Same locked-term issue, plus restoring it would imply password is mandatory, which it isn't.
- **Nickname help text "Shown to your peer instead of PEER"** (audit Medium #7): rejected. Nicknames are local-only today. The "LOCAL ONLY" badge says so. Adopting the design's copy would be a UX lie. Keep impl.
- **Bubble sender labels `.toUpperCase()`** (audit Low #11): rejected. Task 8b explicitly removed this. The lowercase form matches the project's quiet-terminal aesthetic. Locked.

## Status
Done

## Notes
- `flutter analyze`: clean
- `flutter test`: 102 tests (up from 97 in Task 15)
- `npm test`: 43 tests (unchanged)
- No tests referenced "out of band" string — no test updates needed for the copy change.
- New files: `lib/components/caret.dart`, `test/components/caret_test.dart`
- Modified: `home_screen.dart`, `join_room_screen.dart`, `chat_screen.dart`, `room_setup_screen.dart`, `chat_screen_test.dart`
