# Changelog

_Most recent changes appear at the top._

---

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
