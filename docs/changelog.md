# Changelog

_Most recent changes appear at the top._

---

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
