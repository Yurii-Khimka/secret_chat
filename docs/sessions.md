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

### Phase 1 — Foundation 🔜 next
- [x] Merge Phase 0 branches into `main`
- [x] Node.js server skeleton
- [x] WebSocket connection + TLS
- [x] Room creation (server-side code generation, in-memory only)
- [x] Room join flow (peer pairing by code)
- [x] Real-time message relay (encrypted payload pass-through, server cannot read)
- [ ] Connection lifecycle + cleanup on disconnect

### Phase 2 — Security
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
