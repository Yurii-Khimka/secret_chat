# Changelog

_Most recent changes appear at the top._

---

## 2026-05-06 — Task 9: E2E encryption

- Added `cryptography: ^2.7.0` dependency (resolved 2.9.0)
- Created `lib/network/crypto.dart`: Argon2id KDF (m=19456, t=2, p=1, len=32) + XChaCha20-Poly1305 AEAD
- Salt = SHA-256(roomCode)[0..16) — deterministic, no handshake needed
- ChatClient: password-mode first message derives key, encrypts phrase, drains buffered peer messages
- ChatMessage (renamed from IncomingMessage): added `decryptFailed` flag
- Protocol: `msg` frame now carries `text` (open) or `ciphertext`+`nonce` (password) — not `payload`
- Server: validates msg shape, cross-checks room passwordMode, 4096-char field cap
- ChatScreen: "type the phrase…" hint when key not yet set
- Tests: flutter 59 (was 36), server 39 (was 35)
- Branch: task/e2e-encryption
- Commit: feat: e2e encryption — argon2id key derivation + xchacha20-poly1305 messages

## 2026-05-06 — Task 8c: Phrase-mode message wrap fix

- Removed hard `\n` line breaks from phrase-mode SystemMessage string in chat_screen.dart
- Body is now one continuous paragraph — Flutter wraps to container width naturally
- Single `\n` kept between `// phrase mode` header and body (triggers multi-line branch)
- Branch: task/phrase-message-wrap
- Commit: fix: phrase-mode message wraps naturally — drop hard line breaks

## 2026-05-06 — Task 8b: Chat UX polish

- SystemMessage: multi-line text left-aligned with `TextAlign.start`; single-line stays centered
- ChatClient: added `isHost` (bool?) and `localNickname` (String?) — set on create/join, cleared on close
- Bubble labels: replaced hardcoded `YOU`/`PEER` with role/nickname-aware `_labelFor()` helper
- Removed `.toUpperCase()` from MessageBubble — labels render lowercase as-is
- Wired nickname controllers from RoomSetupScreen and JoinRoomScreen into ChatClient calls
- Tests: flutter 36/36 (was 27), server 35/35 unchanged
- Branch: task/chat-ux-polish
- Commit: feat: chat ux polish — left-align multiline system messages, role/nickname bubble labels

## 2026-05-05 — Task 8: Room Setup + password_mode protocol flag

- Server: `create_room` accepts `password_mode` bool, echoed in `room_created`, included in `joined` for joiner
- Renamed `RoomCreatedScreen` -> `RoomSetupScreen` with two-state flow (setup -> code generated)
- Created `AppToggle` component for password mode switch
- Removed PASSWORD field from JoinRoomScreen; added info text about creator-controlled mode
- ChatScreen shows phrase-mode system message when `passwordMode == true`
- No crypto yet -- messages remain plaintext for both modes (Task 9)
- Tests: flutter 27/27 (was 19), server 35/35 (was 29)
- Branch: task/room-setup-mode
- Commit: feat: room setup screen + password mode protocol flag

## 2026-05-05 — Task 7 closed — live verification

- J.3–J.7 PASS on iPhone 17 simulator + real server + wscat
- Lifecycle survives backgrounding (detached-only fix confirmed)
- Branch ready for merge at Task 8 start
- Branch: task/flutter-network-client
- Commit: docs: close out task 7 — owner-verified J.3–J.7 pass

## 2026-05-05 — Task 7b: live verification + UX closeout

- PASSWORD field on JoinRoomScreen: added `// password gate arrives in task 8` helper text (muted)
- Lifecycle: removed `paused` trigger from `chatClient.close()` — only `detached` now
- ChatScreen: added `[plaintext — encryption arrives in task 9]` warning banner (extended `SystemMessage` with `tone: warning`)
- J.1–J.7 manual verification: blocked (no simulator in this environment)
- Branch: task/flutter-network-client (same branch, no merge)
- Commit: fix: live verification + ux closeout for flutter network client

## 2026-05-05 — Flutter WebSocket client + real pairing

- Added `web_socket_channel ^3.0.0`; created `lib/network/` with server_config, protocol (sealed classes), chat_client (ChangeNotifier)
- Wired all 4 screens to real server: create room, join room, live chat, peer disconnect
- App lifecycle observer: paused/detached → close client
- Error codes mapped to fixed UI strings (never echo server reason)
- 15 protocol tests, 4 existing widget tests still pass
- No crypto yet — plaintext payloads (Phase 2 tasks 8–9)
- Branch: task/flutter-network-client
- Commit: feat: flutter websocket client and real-server pairing

## 2026-05-05 — Lifecycle hardening + Phase 1 closeout

- Documented shutdown contract verbatim in server.js and README
- `attachWebSocket` returns `{ wss, teardown }` — teardown called in `close()` before `server.close()`
- Dropped deprecated `removeRoom(code)` (zero callers)
- Added 5-second hard timeout on SIGINT/SIGTERM in index.js
- 2 lifecycle tests (shutdown timing + no leaked timers), 29 total
- Phase 1 complete
- Branch: task/server-lifecycle-hardening
- Commit: chore: lifecycle hardening — shutdown contract, drop deprecated removeRoom

## 2026-05-05 — Opaque-payload message relay

- Added `msg` message type for bidirectional relay between paired peers
- Server forwards `payload` verbatim — no decode, no transform, no inspection, no logging
- Added `getPeer(ws)` helper in rooms.js (state-reading only)
- New error codes: `not_in_room`, `not_paired`
- Raised `MAX_FRAME_SIZE` from 1 KB to 16 KB (fits AES-256-GCM ciphertext + base64)
- 8 relay tests added (27 total)
- Branch: task/server-relay
- Commit: feat: opaque-payload message relay between paired peers

## 2026-05-05 — Room join + peer pairing

- Extended protocol with join_room, joined, peer_joined, peer_left message types
- Added joinRoom (returns discriminated union) and leaveRoom to rooms.js — state only, no I/O
- 1:1 pairing enforced: room_full, cannot_join_own, already_in_room errors
- Either disconnect destroys room, survivor gets peer_left
- CODE_REGEX validation on incoming code fields
- Branch: task/server-room-join
- Commit: feat: 1:1 room join with peer pairing and disconnect notifications

## 2026-05-05 — Room creation (in-memory)

- Added wire protocol module (protocol.js): `hello`, `create_room`, `room_created`, `error`
- Added 64-word list for WORD-NNNN room codes (crypto.randomInt, collision retry)
- Added in-memory room registry (rooms.js): createRoom, removeRoom, ws.roomCode binding
- Message handler in ws.js: parses frames (1KB cap), dispatches create_room, rejects unknowns
- Error frames never echo client content; no new log lines on data path
- Branch: task/server-room-creation
- Commit: feat: room creation with in-memory registry and wire protocol v0.1

## 2026-05-05 — WebSocket + optional TLS

- Added `ws@^8` (sole runtime dep); refactored server into server.js + ws.js
- WebSocket endpoint on configurable path (default `/ws`), sends hello frame on connect
- Optional TLS via `TLS_CERT_PATH` + `TLS_KEY_PATH` env vars
- Heartbeat ping/pong every 30s, terminates stale clients
- No client data logged — hard rule comment at ws.js:1-6
- Branch: task/server-websocket-tls
- Commit: feat: websocket endpoint with optional TLS and hello frame

## 2026-05-05 — Node.js server skeleton

- Created `server/` directory with HTTP server, /health endpoint, config, and logger
- Zero runtime/dev dependencies — Node built-in modules only (http, test)
- Logger enforces hard rule: no client-derived data ever logged
- Smoke test: GET /health → 200, GET /nope → 404
- Branch: task/server-skeleton
- Commit: feat: node.js server skeleton with /health endpoint

## 2026-05-05 — Settings screen + theme picker + persistence tests

- Built SettingsScreen with 5 theme rows (accent swatch + name + active marker) and kDebugMode-gated Developer section
- Added ⚙ SETTINGS entry point to HomeScreen top bar
- Made SecretChatApp controller injectable for testability
- Added 3 end-to-end persistence tests: cold-start with stored theme, default fallback, and runtime persist via Settings UI
- Branch: task/settings-and-theme-picker
- Commit: feat: settings screen with theme picker and persistence verification
- 5-task plan complete — ready for Phase 1 networking

## 2026-05-05 — Four screens + navigation

- Built 4 screens: HomeScreen, RoomCreatedScreen, JoinRoomScreen, ChatScreen
- Full navigation: Home → RoomCreated (push) → Chat (replace), Home → JoinRoom (push) → Chat (replace), Chat → Home (popUntil first)
- CodeBlock input with 8-slot auto-advance, clipboard copy on RoomCreated, dummy chat send
- Replaced ComponentGalleryScreen with HomeScreen as app entry; gallery preserved in lib/dev/
- Branch: task/screens
- Commit: feat: home, room created, join room, and chat screens with navigation

## 2026-05-05 — Component library + dev gallery

- Built 8 components in lib/components/: AppScaffold, AppButton, AppTextField, AppText, MessageBubble, RoomCodeDisplay, PulseDot, SystemMessage
- Created dev-only ComponentGalleryScreen with theme picker and all component states
- Replaced Task 2 smoke screen with gallery as app home
- All components read from active AppTheme — zero hardcoded values
- Branch: task/component-library
- Commit: feat: component library and dev component gallery

## 2026-05-05 — Design tokens, 5 theme palettes, ThemeController

- Created lib/tokens/tokens.dart with AppSpacing, AppRadii, AppDurations, AppTypography, AppPalette (18 semantic color slots)
- Created 5 palette files under lib/theme/palettes/ (Mint default, Ice, Indigo, Sand, Lime) — all hex values from design JSX
- Created AppThemeName enum, AppTheme factory, ThemeController with shared_preferences persistence
- Replaced boilerplate main.dart with smoke-test screen showing active theme + palette swatches
- Updated widget test
- Branch: task/design-tokens
- Commit: feat: design tokens, 5 theme palettes, and theme controller

## 2026-05-05 — Flutter scaffold + Claude Design fetched

- Fetched design bundle from Claude Design API and saved to docs/design/
- Scaffolded Flutter project with iOS + Android platforms
- Added google_fonts and shared_preferences dependencies
- Verified with flutter analyze — no issues
- Branch: task/flutter-scaffold
- Commit: chore: scaffold Flutter project and fetch Claude Design reference

## 2026-05-05 — Project setup

- Created documentation structure
- Files: claude.md, chat.md, readme.md, plan.md, result.md, changelog.md, sessions.md
- Branch: task/project-setup
- Commit: docs: initialise project documentation structure
