# Sessions

---

## Roadmap

### Phase 0 — Project setup & UI scaffolding ✅ complete
- [x] Task 0 — Documentation structure (`task/project-setup`)
- [x] Task 1 — Flutter scaffold + Claude Design fetched (`task/flutter-scaffold`)
- [x] Task 2 — Design tokens + 5 theme palettes + ThemeController (`task/design-tokens`)
- [x] Task 3 — Component library + dev gallery (`task/component-library`)
- [x] Task 4 — Four production screens + navigation (`task/screens`)
- [x] Task 5 — Settings screen + theme picker + persistence tests (`task/settings-and-theme-picker`)

### Phase 1 — Foundation ✅ complete
- [x] Merge Phase 0 branches into `main`
- [x] Node.js server skeleton
- [x] WebSocket connection + TLS
- [x] Room creation (server-side code generation, in-memory only)
- [x] Room join flow (peer pairing by code)
- [x] Real-time message relay (encrypted payload pass-through, server cannot read)
- [x] Connection lifecycle + cleanup on disconnect

### Phase 2 — Security
- [x] Task 7 — Flutter WS client + real pairing (no crypto yet) (`task/flutter-network-client`)
- [ ] Argon2 password → key derivation on device
- [ ] AES-256 message encryption on device
- [ ] Verify zero server-side logging (no IPs, no payloads, no metadata beyond room code)
- [ ] Session cleanup on app close (memory wipe)
- [ ] Key verification handshake between peers

### Phase 3 — Polish
- [ ] Connection error handling + retry UX
- [ ] Smooth session management (foreground/background, network drops)
- [ ] Final terminal-UI pass against design
- [ ] App store assets (icons, screenshots, privacy copy)
- [ ] iOS + Android release builds

---

## Session 2026-05-05 — Project setup

### Completed
- Initialised project documentation structure

### Branch
task/project-setup

### Status
Done

---

## Session 2026-05-05 — Flutter scaffold + Claude Design fetched

### Completed
- Fetched Claude Design reference bundle (5 screens, 10 files)
- Scaffolded Flutter project (secret_chat, iOS + Android)
- Added google_fonts and shared_preferences dependencies
- flutter analyze — clean

### Branch
task/flutter-scaffold

### Status
Done

---

## Session 2026-05-05 — Tokens, 5 theme palettes, and ThemeController

### Completed
- Created tokens module (AppSpacing, AppRadii, AppDurations, AppTypography, AppPalette)
- Created 5 theme palettes (Mint, Ice, Indigo, Sand, Lime) with hex values from design
- Created ThemeController with shared_preferences persistence
- Wired smoke-test screen in main.dart
- flutter analyze — clean
- flutter test — 1/1 passed

### Branch
task/design-tokens

### Status
Done

---

## Session 2026-05-05 — Component library + dev gallery

### Completed
- Built 6 required components: AppScaffold, AppButton, AppTextField, AppText, MessageBubble, RoomCodeDisplay
- Built 2 extra components: PulseDot, SystemMessage
- Created dev-only ComponentGalleryScreen with theme picker and all component states
- Wired gallery as app home
- flutter analyze — clean
- flutter test — 1/1 passed

### Branch
task/component-library

### Status
Done

---

## Session 2026-05-05 — Four screens + navigation

### Completed
- Built HomeScreen, RoomCreatedScreen, JoinRoomScreen, ChatScreen
- Wired full navigation: Home → Create Room → RoomCreated → Chat, Home → Join Room → Chat
- CodeBlock input with 8-slot auto-advance FocusNode chain
- Chat composer with local send (dummy, no network)
- Replaced ComponentGalleryScreen with HomeScreen as app entry point
- flutter analyze — clean
- flutter test — 1/1 passed

### Branch
task/screens

### Status
Done

---

## Session 2026-05-05 — Settings screen + theme picker + persistence tests

### Completed
- Built SettingsScreen with 5 theme rows and developer section (kDebugMode gated)
- Added ⚙ SETTINGS entry point to HomeScreen top bar
- Made SecretChatApp controller injectable for testing
- Added 3 persistence tests: cold-start Lime, cold-start Mint fallback, runtime Indigo persist
- flutter analyze — clean
- flutter test — 4/4 passed

### Branch
task/settings-and-theme-picker

### Status
Done

---

## Session 2026-05-05 — Node.js server skeleton

### Completed
- Created server/ directory with HTTP server skeleton (index.js, config.js, log.js)
- /health endpoint returns 200 with version string; everything else 404
- Logger enforces zero client-data policy (comment at log.js:1-5)
- Smoke test passes (2/2) via Node built-in test runner
- flutter analyze + flutter test still clean

### Branch
task/server-skeleton

### Status
Done

---

## Session 2026-05-05 — WebSocket + optional TLS

### Completed
- Added `ws@^8` as sole runtime dependency
- Refactored index.js into server.js (http/https factory) + ws.js (WebSocket attach)
- WebSocket on `/ws` sends `{type:"hello",v:"0.1.0"}` on connect, heartbeat every 30s
- TLS opt-in via TLS_CERT_PATH + TLS_KEY_PATH env vars (half-configured throws)
- config.js exports frozen object with validation
- 5 tests pass (2 HTTP + 3 WebSocket)
- flutter analyze + flutter test still clean

### Branch
task/server-websocket-tls

### Status
Done

---

## Session 2026-05-05 — Room creation (in-memory)

### Completed
- Created protocol.js (wire protocol constants, parseMessage with 1KB cap, errorMessage)
- Created wordlist.js (64 frozen uppercase nouns)
- Created rooms.js (Map registry, createRoom/removeRoom, ws.roomCode binding)
- Updated ws.js with message handler: create_room → room_created, error handling
- Disconnect cleans up room from registry
- 11 tests pass (2 HTTP + 3 WS + 6 Rooms)
- flutter analyze + flutter test still clean

### Branch
task/server-room-creation

### Status
Done

---

## Session 2026-05-05 — Room join + peer pairing

### Completed
- Extended wire protocol: join_room, joined, peer_joined, peer_left
- Added joinRoom (discriminated union return) and leaveRoom to rooms.js
- rooms.js does state only — zero ws.send calls (I/O in ws.js only)
- Either party disconnecting destroys room and notifies survivor with peer_left
- 19 tests pass (11 prior + 8 pairing scenarios)
- flutter analyze + flutter test still clean

### Branch
task/server-room-join

### Status
Done

---

## Session 2026-05-05 — Encrypted-payload relay (opaque)

### Completed
- Added `msg` message type for opaque-payload relay between paired peers
- Server forwards payload verbatim — zero logging on relay path
- Added `getPeer(ws)` helper, `not_in_room` / `not_paired` error codes
- Raised frame cap to 16 KB
- 8 relay tests (27 total), all pass
- flutter analyze + flutter test still clean

### Branch
task/server-relay

### Status
Done

---

## Session 2026-05-05 — Lifecycle hardening + Phase 1 closeout

### Completed
- Audited and documented shutdown contract in server.js (verbatim comment)
- `attachWebSocket` now returns `{ wss, teardown }` — teardown called explicitly in `close()`
- Dropped deprecated `removeRoom(code)` — zero callers remained
- Added 5-second hard timeout on SIGINT/SIGTERM in index.js
- 2 lifecycle tests: shutdown with 5 clients < 500ms, no leaked timers
- 29 tests pass (27 prior + 2 lifecycle)
- flutter analyze + flutter test still clean
- Phase 1 ✅ complete

### Branch
task/server-lifecycle-hardening

### Status
Done

---

## Session 2026-05-05 — Flutter network client + real pairing

### Completed
- Added `web_socket_channel ^3.0.0` dependency (sole new dep)
- Created `lib/network/`: `server_config.dart`, `protocol.dart` (sealed classes + builders), `chat_client.dart` (ChangeNotifier state machine)
- Wired HomeScreen: CREATE ROOM calls server, shows CONNECTING... state, pushes RoomCreatedScreen on success
- Wired RoomCreatedScreen: reads code from ChatClient, listens for peer_joined → auto-navigates to ChatScreen
- Wired JoinRoomScreen: CONNECT validates code, sends join_room, error mapping table, navigates on paired
- Wired ChatScreen: live message list from ChatClient, peer_left shows system message + disables composer
- App lifecycle: paused/detached → chatClient.close() (first piece of "everything deleted on close")
- 15 protocol unit tests + 4 existing widget tests pass (19 total)
- Zero payload logging in ChatClient (grep verified)
- Server tests still 29/29

### Branch
task/flutter-network-client

### Status
Done

---

## Session 2026-05-05 — Task 7b — live verification + UX closeout

### Completed
- PASSWORD field: added `// password gate arrives in task 8` helper text below the field
- Lifecycle: removed `paused` branch — only `detached` triggers `chatClient.close()`
- ChatScreen: added plaintext warning banner via extended `SystemMessage` (tone: warning)
- Extended `SystemMessage` with `SystemMessageTone` enum (muted/warning) — no new component
- flutter analyze clean, flutter test 19/19, npm test 29/29

### Blocked
- J.3–J.7 manual verification requires a running simulator — not available in this environment

### Branch
task/flutter-network-client

### Status
Partially done — UX fixes complete, manual verification blocked

---

## Session 2026-05-05 — Task 7c — Owner-verified J.3–J.7 PASS, Task 7 closed

### Completed
- Owner ran J.1–J.7 on iPhone 17 simulator + real server + wscat — all PASS
- Backgrounding app preserves session (detached-only lifecycle verified)
- Docs updated to reflect verified status; Task 7 is fully closed

### Branch
task/flutter-network-client

### Status
Done

---

## Session 2026-05-06 — Task 8c: Phrase-mode message wrap fix

### Completed
- Removed hard `\n` breaks from phrase-mode SystemMessage string
- Kept single `\n` between header and body for multi-line branch trigger
- Body is now a single paragraph — Flutter wraps naturally
- Removed unused import lint warning in test file
- flutter analyze: clean, flutter test: 36/36, npm test: 35/35

### Branch
task/phrase-message-wrap

### Status
Done

---

## Session 2026-05-06 — Task 8b: Chat UX polish

### Completed
- SystemMessage: multi-line text left-aligned, single-line stays centered
- ChatClient: added `isHost` + `localNickname` state fields
- ChatScreen: bubble labels use role/nickname instead of YOU/PEER
- Removed `.toUpperCase()` from MessageBubble
- Wired nickname from RoomSetupScreen and JoinRoomScreen into ChatClient
- flutter analyze: clean, flutter test: 36/36 (was 27), npm test: 35/35

### Branch
task/chat-ux-polish

### Status
Done

---

## Session 2026-05-05 — Task 8: Room Setup + password_mode protocol flag

### Completed
- Server: `create_room` accepts `password_mode`, `room_created` echoes it, `joined` includes it for joiner
- Client: `ChatClient.createRoom(passwordMode:)` + getter, protocol classes updated
- Renamed `RoomCreatedScreen` → `RoomSetupScreen` with two-state flow (configuring → code generated)
- Removed PASSWORD field from JoinRoomScreen, added info text
- ChatScreen: conditional system message based on `passwordMode`
- Created `AppToggle` component, extended `AppTextField` with `enabled`/`maxLength`
- flutter analyze: clean, flutter test: 27/27, npm test: 35/35

### Branch
task/room-setup-mode

### Status
Done

---

## Phase 2 — Confirmed Constraints (locked 2026-05-05)

These decisions are locked for the rest of Phase 2 (Argon2 + AES). Future tasks must not deviate without an explicit Tech Lead / Owner re-decision.

### 1:1 only — no multi-user
- One chat = exactly two participants. No N-party support, ever.
- Multi-user is **deferred indefinitely** — out of scope for Phase 2 and Phase 3.

### Phrase model — exact match, no retry
- Phrase agreed **out-of-band** by users (in person, signal, etc.). The app never handles the agreement.
- Phrase match is **100% exact, case-sensitive**. No trimming, normalisation, or fuzzy matching.
- On mismatch: **no retry**. User must leave the room and reconnect from scratch.
- Mismatch is **visible to both sides** (each side's AES-GCM auth tag fails on the peer's first message).

### Phrase / key — never stored, never exposed
- Phrase is **never stored** to disk, shared_preferences, keychain, or memory beyond the derivation step.
- Phrase is **never displayed** in the UI, never copyable, never logged.
- Derived AES key is **never displayed**, never copyable, never logged, never sent to the server.
- Salt for Argon2id = **room code** (UTF-8 bytes). Both peers derive the same key independently.

### Terminology (locked — use these exact words in UI and code)
- **Room code** — `WOLF-7342`-style identifier from server. Sharable. Displayed and copyable in the UI.
- **Phrase** — the human secret both users type. Never displayed.
- **Key** — 256-bit AES key derived from `Argon2id(phrase, room_code)`. Never exposed.

### Password mode — toggle on RoomCreatedScreen
- Default: **OFF** (no-password mode — encrypted with hardcoded default key, equivalent to obfuscation).
- Toggle lives on the **existing RoomCreatedScreen**. No new configuration screen.
- Existing nickname feature is preserved as-is.
- When ON: composer accepts only the phrase as the first message; locks until phrase match is confirmed; unlocks for real chat on success; shows mismatch state on failure.

### UX over server flag for password-mode signalling
- Joiner is told via **clear UI explanation** on ChatScreen, not a server protocol field.
- Server protocol is **not extended** with a `password_required` boolean — keep the wire small.
- A future task may add a server flag if UX proves insufficient; not now.

### Crypto stack
- **Argon2id**, parameters: `m = 64 MB, t = 3, p = 1, length = 32 bytes`. Salt = room code (UTF-8). Acknowledged: salt is below OWASP 16-byte minimum; accepted because chat is ephemeral and Argon2id cost is the actual barrier.
- **AES-256-GCM**. **Random 12-byte IV per message**, never reused. IV transmitted alongside ciphertext (not secret).
- Decryption failure (auth tag mismatch) is caught and surfaced as a UI label, never as a crash.
- No-password mode uses a **hardcoded 256-bit default key** baked into the binary. UI must clearly state this is not real protection.
