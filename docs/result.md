# Last Task Result

## Task
Design tokens, 5 theme palettes, and ThemeController (Task 2 of 5).

## Branch
task/design-tokens

## Commit
feat: design tokens, 5 theme palettes, and theme controller

## What Was Done

### File tree under lib/
```
lib/
├── main.dart                          (smoke-test wire-up)
├── tokens/
│   └── tokens.dart                    (AppSpacing, AppRadii, AppDurations, AppTypography, AppPalette)
└── theme/
    ├── app_theme_name.dart            (enum AppThemeName)
    ├── app_theme.dart                 (AppTheme with factory forName)
    ├── theme_controller.dart          (ThemeController with shared_preferences)
    └── palettes/
        ├── mint_palette.dart          (default)
        ├── ice_palette.dart
        ├── indigo_palette.dart
        ├── sand_palette.dart
        └── lime_palette.dart
```

### AppPalette slot descriptions

| Slot | Intent |
|------|--------|
| background | Deep near-black background — T.bg |
| surface | Slightly elevated surface — T.surface |
| surfaceMuted | Higher elevation surface — T.surfaceHi |
| border | Faint hairline border — T.hairline |
| borderHighlight | Highlighted border — T.hairlineHi |
| textPrimary | Primary foreground text — T.fg |
| textSecondary | Dimmed secondary text — T.fgDim |
| textMuted | Muted text for labels/hints — T.fgMute |
| accent | Theme accent color — per-theme from ACCENTS |
| accentMuted | Dimmed accent at 55% opacity |
| accentText | Text on accent-filled surfaces |
| accentGhost | Very faint accent tint for backgrounds (14%) |
| accentGlow | Accent glow for shadows (32%) |
| bubbleSent | Sent message bubble background |
| bubbleSentText | Sent message bubble text |
| bubbleReceived | Received message bubble background |
| bubbleReceivedText | Received message bubble text |
| warning | Warning color — T.warn |

### 5 theme palettes — hex values

| Slot | Mint | Ice | Indigo | Sand | Lime |
|------|------|-----|--------|------|------|
| background | #0A0D0B | #0A0D0B | #0A0D0B | #0A0D0B | #0A0D0B |
| surface | #101512 | #101512 | #101512 | #101512 | #101512 |
| surfaceMuted | #141A17 | #141A17 | #141A17 | #141A17 | #141A17 |
| border | rgba(180,220,200,0.08) | rgba(180,220,200,0.08) | rgba(180,220,200,0.08) | rgba(180,220,200,0.08) | rgba(180,220,200,0.08) |
| borderHighlight | rgba(127,224,163,0.18) | rgba(168,232,224,0.18) | rgba(154,166,255,0.18) | rgba(232,212,154,0.18) | rgba(200,240,138,0.18) |
| textPrimary | #E2E6E2 | #E2E6E2 | #E2E6E2 | #E2E6E2 | #E2E6E2 |
| textSecondary | #8A918A | #8A918A | #8A918A | #8A918A | #8A918A |
| textMuted | #525A52 | #525A52 | #525A52 | #525A52 | #525A52 |
| **accent** | **#7FE0A3** | **#A8E8E0** | **#9AA6FF** | **#E8D49A** | **#C8F08A** |
| accentMuted | #7FE0A3 @55% | #A8E8E0 @55% | #9AA6FF @55% | #E8D49A @55% | #C8F08A @55% |
| accentText | #06180E | #061816 | #060818 | #181406 | #0E1806 |
| accentGhost | accent @14% | accent @14% | accent @14% | accent @14% | accent @14% |
| accentGlow | accent @32% | accent @32% | accent @32% | accent @32% | accent @32% |
| bubbleSent | accent @8% | accent @8% | accent @8% | accent @8% | accent @8% |
| bubbleSentText | #E2E6E2 | #E2E6E2 | #E2E6E2 | #E2E6E2 | #E2E6E2 |
| bubbleReceived | #101512 | #101512 | #101512 | #101512 | #101512 |
| bubbleReceivedText | #E2E6E2 | #E2E6E2 | #E2E6E2 | #E2E6E2 | #E2E6E2 |
| warning | #E6C067 | #E6C067 | #E6C067 | #E6C067 | #E6C067 |

### Verification
- `flutter analyze` — No issues found
- `flutter test` — All tests passed (1/1)

## Status
Done

## Notes
- All hex values extracted from design JSX prototypes — none invented
- Neutrals (bg, surface, text, border, warning) are shared across all themes; only accent-derived slots vary
- Smoke screen in main.dart shows theme name + tappable theme selector + color swatches — will be deleted in Task 3
- Widget test updated to match new app structure
