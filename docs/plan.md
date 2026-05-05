# Plan

_Updated by the Tech Lead chat before each task._

## Status

**Active task:** Phase 2 / Task 8 — **Room Setup screen + `password_mode` protocol flag**.

This is the first of three tasks that deliver the "chat with password" feature. Task 8 is **UX + protocol only — no crypto yet**. We:

1. Replace the immediate-create flow with a Room Setup screen where the creator configures nickname + password mode before generating the code.
2. Add a `password_mode: bool` flag to `create_room` / `room_created` / `joined`. The server learns the mode (so it can tell the joiner) but never the phrase.
3. In ChatScreen, show a different system message at the top when `password_mode` is true — explaining the phrase model.
4. Remove the obsolete PASSWORD field from JoinRoomScreen (joiner does not pick the mode).

The actual key derivation (Argon2id) and message encryption (XChaCha20-Poly1305) land in **Task 9**. Decryption-failure UX (raw garbled output) lands in **Task 10**.

## Context

### The phrase-as-key model (read this carefully — it shapes every UX decision)

The "password" is not a password. It is the **first message both users type into the chat**. That message is run through a KDF locally to derive a symmetric key; messages are encrypted with that key. The server never sees the phrase. "Match" is implicit: same phrase → same key → ciphertext decrypts. Mismatch → recipient sees gibberish.

Users agree on the phrase **out of band** (in person, another app). Case-sensitive exact match.

This means:
- There is **no password input field** anywhere in the app.
- The creator picks the **mode** (password ON/OFF) at room setup. The joiner does not pick — they're told by the server which mode the room is in.
- ChatScreen's UX differs based on mode: password-mode shows a system message instructing the user to type the agreed phrase as their first message.

Task 8 ships the mode toggle and the system message. It does **not** ship the KDF or any encryption — messages are still plaintext for both modes after Task 8. Task 9 makes password mode actually encrypt.

### Where Task 7 left things

- Branch `task/flutter-network-client` is closed out and ready to merge.
- `lib/screens/room_created_screen.dart` already has aspirational copy for "Set a nickname (optional)" and "Agree on a password (optional)" steps — Task 8 turns those into real controls.
- `lib/screens/join_room_screen.dart` still has an obsolete PASSWORD field with a `// password gate arrives in task 8` helper. Task 8 removes both.
- `lib/screens/chat_screen.dart` shows a `[plaintext — encryption arrives in task 9]` warning banner unconditionally. Task 8 makes this conditional on mode.

## Read First

- [CLAUDE.md](../CLAUDE.md)
- [docs/result.md](result.md) — current Task 7 closeout
- [docs/sessions.md](sessions.md)
- [docs/changelog.md](changelog.md)
- [lib/screens/home_screen.dart](../lib/screens/home_screen.dart) — to see how CREATE ROOM is currently triggered
- [lib/screens/room_created_screen.dart](../lib/screens/room_created_screen.dart) — current screen, will be replaced/repurposed
- [lib/screens/join_room_screen.dart](../lib/screens/join_room_screen.dart) — obsolete PASSWORD field lives here
- [lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart) — system message banner location
- [lib/network/chat_client.dart](../lib/network/chat_client.dart) — needs `passwordMode` state + payload changes
- [server/src/protocol.js](../server/src/protocol.js) — message type constants
- [server/src/rooms.js](../server/src/rooms.js) — Room state
- [server/src/server.js](../server/src/server.js) — message handlers

## Current Task

### Part A — Branching

1. Switch to `main`. Merge `task/flutter-network-client` into `main` (no fast-forward — preserve the merge commit so history shows the task boundary).
2. Delete the local `task/flutter-network-client` branch.
3. Branch off `main` as `task/room-setup-mode`. All Task 8 work lives there.

If anything looks unexpected during the merge (uncommitted state, conflicts), stop and ask before proceeding.

### Part B — Server protocol changes

1. **`create_room` payload** — accept an optional `password_mode` field. Validation:
   - If absent → treat as `false`.
   - If present and not strictly boolean → reject with `error` code `bad_request`, reason `"invalid password_mode"` (use a fixed server string per existing convention).
2. **Room state** ([server/src/rooms.js](../server/src/rooms.js)) — store `passwordMode: boolean` on the Room object alongside the existing fields.
3. **`room_created` response** — include `password_mode` (echo what the creator set, after defaulting).
4. **`joined` event sent to the joiner** — include the room's `password_mode` so the joiner's client knows.
5. **`peer_joined` event sent to the creator** — does NOT need it (creator already knows the mode they set). Do not add it there.
6. Server **never logs** the password_mode value next to anything that could be cross-referenced as a fingerprint. (It's a single bit; this is paranoia, but worth a one-line comment near the log call to make intent explicit.)

### Part C — `ChatClient` changes ([lib/network/chat_client.dart](../lib/network/chat_client.dart))

1. Add a `bool _passwordMode = false;` field with a public `passwordMode` getter.
2. `createRoom(...)` gains a `bool passwordMode` parameter (default `false`). Include it in the outgoing `create_room` payload.
3. On receiving `room_created`: set `_passwordMode` from the server's response, `notifyListeners()`.
4. On receiving `joined` (joiner side): set `_passwordMode` from the server's payload, `notifyListeners()`.
5. Add unit tests for both directions in [test/network/chat_client_test.dart](../test/network/chat_client_test.dart).

### Part D — RoomSetupScreen (replaces RoomCreatedScreen as the entry-after-tap)

Rename `room_created_screen.dart` → `room_setup_screen.dart`; rename `RoomCreatedScreen` → `RoomSetupScreen`. Update the import in `home_screen.dart` and any other call site.

Behaviour — single screen, two visual states:

**State 1: configuring (before "Generate Code" tap)**
- Header: `ROOM SETUP` (replace `ROOM CREATED`).
- Code area: shows a placeholder dashed code (`----`-style) — purely visual, no copy button active yet.
- Nickname input: a single text field, monospace, max 24 chars. Stored locally in screen state. **Do not wire to the server in Task 8** — it's local-only display for now (used in the user's own header in a later task). Helper text below: `// optional — visible only to you (peer-visible nicknames arrive later)`.
- Password mode: a clearly-labeled toggle. Use existing components if a Switch/Toggle exists; otherwise add a minimal one in `lib/components/`. Label: `PASSWORD MODE`. Helper text below the toggle when ON: `// you and your peer will need to agree on a shared phrase before chatting. type it as your first message.` (lowercase, terminal-style, muted color).
- Primary CTA at the bottom: `GENERATE CODE`.

**State 2: code generated (after CTA tap)**
- Calls `chatClient.createRoom(passwordMode: <toggle value>)`.
- Once `room_created` arrives:
  - Header switches to `ROOM CREATED` + `WAITING FOR PEER` (existing copy).
  - Code becomes the real code with the existing copy button.
  - Nickname input becomes read-only (still displayed for reference).
  - Password mode toggle becomes read-only and shows an indicator like `[locked]` next to it.
  - The CTA disappears.
  - Existing `_StepRow` checklist stays — but rewrite step 03 from `Agree on a password (optional)` to one of:
    - if password mode ON: `Agree on a shared phrase out of band`
    - if password mode OFF: omit the row entirely (don't show the obsolete password step).
- When peer joins (`paired` state), navigate to ChatScreen exactly as today.

Do **not** add an explanatory dialog/modal about phrase mode here. The full explanation lives in ChatScreen as a system message (Part F).

### Part E — JoinRoomScreen cleanup ([lib/screens/join_room_screen.dart](../lib/screens/join_room_screen.dart))

1. Remove the PASSWORD field, its label, its `_passwordController`, its disposal, and the `// password gate arrives in task 8` helper text.
2. Add a small system message in the same area: `// password mode is set by the room creator. you'll be told on connect.` (muted tone, single line). This keeps the visual rhythm of the screen and explains why there's no password input.
3. Update any test in [test/screens/join_room_screen_test.dart](../test/screens/join_room_screen_test.dart) that referenced the password field.

### Part F — ChatScreen system message ([lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart))

Today the chat shows a single warning banner: `[plaintext — encryption arrives in task 9]`.

After Task 8:
- If `chatClient.passwordMode == false` → keep the existing plaintext warning banner unchanged.
- If `chatClient.passwordMode == true` → replace it with a phrase-mode system message at the top of the message list. Copy:

  ```
  // phrase mode
  this room requires a shared phrase. type the phrase you agreed on
  with the other participant as your first message. it acts as the
  encryption key — messages will be unreadable without an exact
  case-sensitive match. (encryption arrives in task 9)
  ```

  Render via the existing `SystemMessage` component with `SystemMessageTone.warning`. Multi-line is fine — keep it as a single SystemMessage instance (don't fragment it).

Reuse the existing `SystemMessage` component — do not create a new component for this. Per CLAUDE.md §8, all instances of the same element must look identical.

The "(encryption arrives in task 9)" parenthetical is the temporary stub; Task 9 removes it.

### Part G — Tests

Add or update:

**Server (vitest under `server/`):**
- `create_room` with `password_mode: true` → `room_created` echoes `password_mode: true`.
- `create_room` with `password_mode: false` → echoes `false`.
- `create_room` with `password_mode` absent → defaults to `false`.
- `create_room` with `password_mode: "yes"` (or any non-bool) → `error` with code `bad_request`.
- After a peer joins a `password_mode: true` room → the `joined` event delivered to that peer includes `password_mode: true`.
- After a peer joins a `password_mode: false` room → the `joined` event includes `password_mode: false`.

**Flutter (`flutter test`):**
- `ChatClient.createRoom(passwordMode: true)` puts the flag in the outgoing payload (use the existing test harness / mock socket).
- `ChatClient` updates `passwordMode` getter when `room_created` carries the field (creator side).
- `ChatClient` updates `passwordMode` when `joined` carries the field (joiner side).
- `RoomSetupScreen` renders nickname input + password toggle + Generate Code CTA in State 1.
- Toggling password mode and tapping Generate Code calls `chatClient.createRoom(passwordMode: true)`.
- After `room_created`, the toggle is read-only and code is shown.
- `ChatScreen` with `passwordMode: false` shows the existing plaintext warning (existing test should still pass).
- `ChatScreen` with `passwordMode: true` shows the phrase-mode system message (new test).
- `JoinRoomScreen` no longer has a PASSWORD field (regression test — finder should return nothing).

All existing tests must continue to pass. Don't bypass red tests by editing assertions unless the assertion was genuinely tied to removed behavior — if you delete a test, justify it in the result.md notes.

### Part H — Commit

One commit at the end:

`feat: room setup screen + password mode protocol flag`

### Part I — Output (in your response and at the top of `result.md`)

- Confirm `flutter analyze` is clean.
- Confirm `flutter test` count (should grow vs. Task 7's 19/19).
- Confirm `cd server && npm test` count (should grow vs. Task 7's 29/29).
- Confirm `git diff --name-only main..HEAD` shows the expected files.
- A "what's next" line: live verification of the new flow happens in Task 8b after the Owner runs the simulator (analogous to Task 7c). Do NOT attempt manual sim verification yourself.

### Part J — Update docs/result.md, docs/sessions.md, docs/changelog.md

Per CLAUDE.md §4–§6.

## Specs

- Branch: `task/room-setup-mode` (off `main`, after merging Task 7's branch in).
- One commit at the end.
- Mode toggle is creator-only. Server stores it as a single boolean per room. Joiner is told via the `joined` event.
- No crypto in this task. No Argon2. No cipher. Messages remain plaintext for both modes.
- Reuse `SystemMessage` for the phrase-mode message. Reuse existing toggle/switch component if one exists; if not, create one minimally in `lib/components/` and use it via the design tokens.

## Do NOT

- Do not add Argon2, any KDF, any cipher, or any encryption logic. That is Task 9.
- Do not add a password input field anywhere. Anywhere. The phrase is typed as a chat message, never in a form field.
- Do not add per-message decryption-failure UX (raw garbled output is Task 10).
- Do not wire nickname through to the peer — local display only in this task.
- Do not push the branch.
- Do not skip the merge step in Part A.

## Commit Message

`feat: room setup screen + password mode protocol flag`
