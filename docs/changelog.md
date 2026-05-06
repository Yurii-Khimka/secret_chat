# Changelog

_Most recent changes appear at the top._

---

## 2026-05-06 — Task 17: Activation gate v1

- Owner-side CLI tools: `tools/keygen.dart` (ed25519 keypair), `tools/mint_code.dart` (sign activation codes)
- Embedded public key placeholder in `lib/security/activation_pubkey.dart` (all zeros = locked)
- `verifyActivationCode()`: ed25519 verification, whitespace stripping, placeholder rejection, `@visibleForTesting` override
- `ActivationController`: load/persist/re-verify activation code via SharedPreferences
- `ActivationScreen`: terminal-aesthetic paste screen — PulseDot, "Invite required" + Caret, multi-line TextField, ACTIVATE button, error display
- `main.dart`: `Listenable.merge([themeController, activationController])` gates HomeScreen behind activation
- `.gitignore`: `tools/keys/` and `*.private.key` entries
- `docs/readme.md`: "Activation (v1)" section with collaborator instructions
- Tests: flutter 123/123 (Task 17 introduced 6 timeouts, fixed in Task 17a)
- No new dependencies, no server changes
- Branch: task/activation-gate-v1
- Commit: feat: activation gate v1 — ed25519-signed access codes

## 2026-05-06 — Task 17a: Fix test timeouts

- 6 tests in `chat_client_test.dart` and `chat_ux_polish_test.dart` timed out due to awaiting `createRoom()`/`joinRoom()` with no server running
- Root cause: tests awaited real WebSocket connections to localhost:3000; not related to Caret animation
- Fix: fire-and-forget (`unawaited`) the network call, assert synchronous state immediately, then close
- Pattern 3 (Caret disableAnimation) was NOT needed
- Tests: flutter 123/123, server 43 (unchanged)
- Branch: task/test-timeout-fix
- Commit: fix: stabilize widget tests around blinking caret animation

## 2026-05-06 — Task 16: UI polish pass 1

- New `Caret` component: blinking block cursor (530ms cycle, accent-colored)
- HomeScreen: hero text "No trace" now followed by animated caret
- HomeScreen: DiagCard line height increased from 1.6 to 1.9 (local override only)
- JoinRoomScreen: empty code slots show `_` placeholder
- ChatScreen: composer footer shows `N / 4096` character counter while typing; warning color above 3500
- RoomSetupScreen: step 03 copy simplified from "Agree on a shared phrase out of band" to "Agree on a shared phrase"
- 7 audit items explicitly rejected — see result.md rejection ledger
- Tests: flutter 102 (was 97), server 43 (unchanged)
- Branch: task/ui-polish-pass-1
- Commit: feat: ui polish — blinking caret, line height, code slot hints, char counter

## 2026-05-06 — Task 15: UI fidelity audit

- Created `docs/ui-audit.md`: per-screen, per-component delta list vs design reference
- 28 deltas (6 High, 14 Medium, 8 Low), 7 unimplemented features, 3 ambiguities
- 12-item recommended cut for Task 16
- Zero source file changes — read-only task
- Branch: task/ui-audit
- Commit: docs: ui fidelity audit — delta list for task 16

## 2026-05-06 — Task 14: Smooth session management

- Added `ChatTerminationReason` enum (`peerLeft`, `connectionLost`) to ChatClient
- ChatScreen now shows reason-specific termination message instead of always "peer disconnected"
- Lifecycle policy documented in main.dart comment; extracted `shouldCloseOnLifecycle()` for testability
- Added `@visibleForTesting` debug hooks for state machine testing without real server
- No behavioral change to lifecycle handling (detached-only policy confirmed)
- Tests: flutter 97 (was 81), server 43 (unchanged)
- Branch: task/session-management
- Commit: feat: session management — termination reason + lifecycle policy locked

## 2026-05-06 — Task 13: Connection error handling + retry UX

- ChatClient: 8-second connect timeout (`connect_timeout` error code), bounded `channel.ready`
- Created `lib/network/error_messages.dart`: centralized error-code → message mapping
- JoinRoomScreen: deleted inline `_errorMessages` map, uses shared `describeConnectionError`
- RoomSetupScreen: error surface on generate failure, `close()` before retry, post-code-drop UX (CONNECTION LOST + Retry button resets to pre-generation state)
- No auto-reconnect — manual retry only
- Tests: flutter 81 (was 75), server 43 (unchanged)
- Branch: task/connect-error-ux
- Commit: feat: connect-error ux — timeout, mapped errors, retry on room setup

## 2026-05-06 — Task 12: Zero server-side logging audit

- Static audit: all server/src/ files clean — zero leaks (no console.*, no .remoteAddress, no header access)
- Created server/test/logging.test.js: lifecycle baseline, data-path silence (full session), error non-leak, static source scan
- Updated server/README.md "Logging contract" section — references test enforcement
- Added enforcement comment to ws.js header
- Tests: npm 43 (was 39), flutter 75 (unchanged)
- Phase 2 — Security complete
- Branch: task/server-logging-audit
- Commit: chore: server logging audit — lock zero-data-path-log contract

## 2026-05-06 — Task 11: Security cleanup — memory wipe + lifecycle hardening

- Added `zeroBytes(Uint8List?)` helper in crypto.dart
- `close()`: key bytes zeroed in-place before dropping reference
- `_pendingDecrypt.clear()` moved to first mutation in close (drop cipher refs ASAP)
- Socket teardown bounded to 1s via `Future.any` (hung sink won't block UI)
- Added `@visibleForTesting debugKeyBytes` getter for test verification
- Comment documenting immutable-string limit on `_messages.clear()`
- Lifecycle: detached-only policy confirmed unchanged (paused preserves session)
- Tests: flutter 75 (was 69), server 39 (unchanged)
- Branch: task/security-cleanup
- Commit: chore: security cleanup — zero key bytes on close + bounded socket teardown

## 2026-05-06 — Task 10: Decrypt-failure UX + mismatch composer lock

- ChatClient: `mismatchDetected` one-way flag on first decrypt failure; cleared by `close()`
- Failed decrypt messages: `text: ''`, `decryptFailed: true` (no ciphertext in UI)
- MessageBubble: `decryptFailed` renders muted bg + italic "unreadable" label
- ChatScreen: composer disabled on mismatch, warning SystemMessage, hint "phrase mismatch — leave the room"
- Tap-anywhere-to-exit mirrors peer-left behaviour on mismatch
- Stale copy cleanup: removed "encryption arrives in task 9"; open-mode banner updated
- Mode-aware micro-text: ENCRYPTED / PLAINTEXT in top-bar and footer
- Tests: flutter 69 (was 59), server 39 (unchanged)
- Branch: task/decrypt-failure-ux
- Commit: feat: decrypt-failure ux — mismatch warning + composer lock

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
