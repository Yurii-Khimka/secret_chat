# Sessions

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
