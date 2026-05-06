# UI Fidelity Audit

_Generated: 2026-05-06_
_Audited against: docs/design/screens.jsx + chat1.md_
_Auditor: Claude Code (Task 15)_

## Summary

- Screens audited: 5
- Components audited: 9
- Total deltas: 28
- High severity: 6
- Medium: 14
- Low: 8

## Method

Compared the design reference (screens.jsx tokens, component props, layout structure, copy strings) against the Flutter implementation (lib/screens/, lib/components/, lib/tokens/). Settings screen has no design counterpart and was audited only for consistency with established patterns. Decorative layers (vignette, scanlines, noise) from ScreenBase are classified as unimplemented features, not deltas. Ambiguities in the design (e.g. CSS values with no clear token mapping) are listed in the Ambiguities section rather than counted as deltas.

## Screens

### Home

#### High
- **Header right text**: design says `OFFLINE • E2EE` (screens.jsx:158), impl shows `⚙ SETTINGS` (home_screen.dart:80). The settings entry point replaces the design's status text entirely. Design has no settings entry.
- **Blinking caret missing on hero text**: design shows `No trace` followed by a blinking `Caret` component (screens.jsx:165), impl has plain text without any caret animation (home_screen.dart:108).

#### Medium
- **Header layout order**: design puts PulseDot + text on left, status text on right in `fgMute` color (screens.jsx:66-81). Impl matches left side but the right side is the settings link instead of a status label.
- **Button sub-text letterSpacing**: design uses `letterSpacing: '0.01em'` (~0.14px at 11px) for button sub-text (screens.jsx:123). Impl AppButton caption style uses `letterSpacing: 0.14` (app_button.dart:102) — matches.
- **DiagRow line height**: design uses `lineHeight: 1.9` for the diagnostics card (screens.jsx:172). Impl uses `AppTypography.mono` which has `height: 1.6` (tokens.dart:68). Visible as tighter line spacing in the diagnostics block.
- **Bottom tagline spacing**: design positions buttons absolutely at `bottom: 60` with a `marginTop: 6` above the tagline (screens.jsx:179-184). Impl uses column layout with `SizedBox(height: AppSpacing.md + 6)` = 18px gap (home_screen.dart:173). Different layout mechanism but approximately equivalent.

#### Low
- **Hero heading letterSpacing**: design uses `-0.015em` (~-0.45px at 30px) (screens.jsx:162). Impl `AppTypography.heading` has `letterSpacing: -0.45` (tokens.dart:54) — matches.
- **Diag card padding**: design uses `padding: '14px 16px'` (screens.jsx:172). Impl uses `horizontal: AppSpacing.lg (16), vertical: AppSpacing.md + 2 (14)` (home_screen.dart:124-125) — matches.

### Room Setup

#### High
- **Design shows "Set Nickname & Password" CTA and "Cancel Room" button** in the code-generated state (screens.jsx:515-516). Impl shows no bottom CTA in the waiting state (only shows retry on error). The design's two-button bottom area is missing.
- **"EXPIRES IN 09:42" countdown**: design shows an expiry timer below the room code (screens.jsx:496-497). Impl has no expiry timer — feature gap (listed in Unimplemented section).

#### Medium
- **Room code display "TAP TO COPY" text**: impl shows this (room_code_display.dart:89). Design shows `EXPIRES IN 09:42` instead (screens.jsx:496). These are different pieces of information; TAP TO COPY is impl-only.
- **Step card copy drift**: design step 03 says "Agree on a password (optional)" (screens.jsx:509). Impl says "Agree on a shared phrase out of band" (room_setup_screen.dart:301). Different terminology ("password" vs "phrase").
- **Descriptive text copy**: design says "Share this code through any channel / outside this app. Then optionally / set a nickname and a password." (screens.jsx:500-503). Impl says "Share this code through any channel / outside this app." — truncated, missing the nickname/password mention (room_setup_screen.dart:279-280).
- **Nickname help text**: design says "Shown to your peer instead of PEER. / Leave blank to stay fully anonymous." (screens.jsx:240-241). Impl says "// optional — visible only to you (peer-visible nicknames arrive later)" (room_setup_screen.dart:236-237). Different meaning: design implies peer-visible, impl says local-only.

#### Low
- **Password mode toggle**: design shows a password input field (screens.jsx:246-268). Impl replaced this with a toggle switch since the password/phrase is entered as first chat message (Task 8 decision). Intentional divergence.

### Join Room

#### Medium
- **Password field missing**: design shows a `// PASSWORD (OPTIONAL)` input field with `$ •••••••••` and `SHA-256 ▸ AES-256` trailing text (screens.jsx:246-268). Impl removed this field (Task 8 decision: phrase is typed as first chat message). Intentional divergence but visually different from design.
- **Nickname help text copy**: design says "Shown to your peer instead of PEER. / Leave blank to stay fully anonymous." (screens.jsx:240-241). Impl matches: "Shown to your peer instead of PEER.\nLeave blank to stay fully anonymous." (join_room_screen.dart:210-211) — correct. But impl adds an additional line below: "// password mode is set by the room creator. you'll be told on connect." (join_room_screen.dart:220-221) which is not in design.
- **Code slot filled background**: design uses `${accent}10` (accent at ~6% opacity) (screens.jsx:291). Impl uses `p.accentGhost` which is `0x247FE0A3` = 14% opacity (mint_palette.dart:18). Slightly more visible than design intent.

#### Low
- **Code slot empty placeholder**: design shows `_` underscore character (screens.jsx:293). Impl shows empty slot with no placeholder character (join_room_screen.dart:264-308). Minor visual difference.
- **Caret in code input**: design shows a blinking cursor line at bottom-right of last filled slot (screens.jsx:294-295). Impl uses standard Flutter cursor. Different cursor treatment.

### Chat

#### High
- **Header sub-row left text**: design shows `FP 4F:9A:21:C0` (fingerprint) (screens.jsx:336). Impl shows mode label `ENCRYPTED` or `PLAINTEXT` (chat_screen.dart:157-160). Different information displayed.
- **Header right status text**: design shows `ENCRYPTED` next to PulseDot (screens.jsx:331-333). Impl shows `CONNECTED` or `DISCONNECTED` (chat_screen.dart:146-149). Different label.

#### Medium
- **Footer left text**: design shows `AES-256-GCM` (screens.jsx:381). Impl shows mode label `ENCRYPTED` or `PLAINTEXT` (chat_screen.dart:304-306). Different string.
- **Footer right text (composing state)**: design shows character count `38 / 4096` (screens.jsx:382). Impl shows `TAP TO TYPE` (chat_screen.dart:309). No character counter implemented.
- **Chat body top padding**: design uses `padding: '16px 16px 8px'` (screens.jsx:348). Impl uses `EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg)` = 16px all around (chat_screen.dart:194-196). Bottom padding differs: 8px vs 16px.
- **Composer input border**: design uses `T.hairlineHi` for the composer border (screens.jsx:363). Impl uses `_composerDisabled ? p.border : p.borderHighlight` (chat_screen.dart:249). Matches when enabled; design doesn't show disabled state.
- **System messages**: design shows `— session opened —` and `peer joined · key verified ✓` as system messages (screens.jsx:307-308). Impl shows phrase-mode or open-mode system messages instead (chat_screen.dart:185-191). Different copy reflecting actual app behavior.

#### Low
- **Back chevron glyph**: design uses `‹` (single character, fontSize 18) (screens.jsx:327). Impl uses `‹` in the same way but with `AppTypography.heading.copyWith(fontSize: 18)` which inherits heading letter-spacing (chat_screen.dart:124-127). Slight font metric difference.
- **Bubble sender label case**: design calls `.toUpperCase()` on label (screens.jsx:406). Impl renders labels as-is (lowercase "host"/"peer") per Task 8b decision (message_bubble.dart:79). Intentional divergence.
- **Bubble border on sent messages**: design uses `accent + '55'` = accent at 33% alpha (screens.jsx:410). Impl uses `palette.accent.withValues(alpha: 0.33)` (message_bubble.dart:45) — matches.

### Settings

Settings screen has no design counterpart in screens.jsx. No deltas to compare against. Internal consistency is acceptable.

## Components

### AppButton
- **Sub-text style**: design uses `textTransform: 'none'` explicitly (screens.jsx:124). Impl caption style doesn't uppercase sub-text (app_button.dart:98) — matches. Clean.

### AppTextField
- Clean — matches design field structure (prefix char, trailing text, minHeight 52, border radius rMd).

### MessageBubble
- **Bubble padding**: design uses `padding: '10px 14px'` (screens.jsx:409). Impl uses `horizontal: AppSpacing.md + 2 (14), vertical: AppSpacing.sm + 2 (10)` (message_bubble.dart:88-89) — matches.

### RoomCodeDisplay
- **Room code letterSpacing**: design uses `letterSpacing: '0.18em'` at 38px = ~6.84px (screens.jsx:492). Impl uses `letterSpacing: 6.84` (room_code_display.dart:52) — matches.

### SystemMessage
- **Font size**: design uses `fontSize: 10` for system messages (screens.jsx:394). Impl uses `AppTypography.micro` which is `fontSize: 10` (tokens.dart:77) — matches.

### PulseDot
- **Glow shadow**: design uses `boxShadow: '0 0 10px ${color}'` (screens.jsx:88). Impl uses `BoxShadow(blurRadius: 10)` (pulse_dot.dart:64) — matches.

Clean: AppButton, AppTextField, AppText, AppToggle, MessageBubble, RoomCodeDisplay, SystemMessage, PulseDot

### AppScaffold
- **Decorative overlays missing**: design's `ScreenBase` includes vignette gradient, scanline overlay, and noise texture (screens.jsx:33-61). Impl `AppScaffold` is a plain `Scaffold` with background color only (app_scaffold.dart:19-38). Listed in Unimplemented section.

## Cross-cutting

- **Header pattern inconsistency**: Home uses PulseDot on left. RoomSetup uses `‹` back + PulseDot + title. JoinRoom uses `‹ BACK / JOIN`. ChatScreen uses `‹` + room code on left, PulseDot + status on right. Design's `TermHeader` is consistent: PulseDot + left text, right text (screens.jsx:66-81). Only HomeScreen follows the design's header pattern closely. Other screens diverge because they need navigation (back buttons).
- **Footer micro-text**: design uses `AES-256-GCM` as the encryption label in ChatScreen (screens.jsx:381). Impl uses `ENCRYPTED`/`PLAINTEXT` mode label across both top-bar and footer (chat_screen.dart:157,304). The label is consistent within impl but differs from design.
- **`// COMMENT` label style**: all screens use `AppTypography.caption` with `p.textMuted` for section labels like `// SESSION`, `// ROOM CODE`, etc. Matches design's `fontSize: 11, color: T.fgMute, letterSpacing: '0.18em'`. Caption style has `letterSpacing: 1.98` at 11px = 0.18em. Consistent.

## Unimplemented from design

- **ScreenBase decorative layers** (vignette, scanlines, noise texture): screens.jsx:33-61. Three stacked overlays for visual atmosphere. Phase 3 polish item — purely cosmetic, no functional impact.
- **Blinking Caret component**: screens.jsx:130-138. Animated block cursor used in hero text, input fields, and composer. Phase 3 polish item.
- **Expiry timer on room code**: screens.jsx:496-497. `EXPIRES IN 09:42` countdown. Requires server-side room TTL. Deeper feature, not a polish item.
- **Fingerprint display**: screens.jsx:336. `FP 4F:9A:21:C0` in chat header. Would require computing a visual fingerprint from the derived key. Deeper feature.
- **Character counter in composer**: screens.jsx:382. `38 / 4096` count while typing. Phase 3 polish item — straightforward to add.
- **"session opened" / "key verified" system messages**: screens.jsx:307-308. Design shows connection lifecycle messages. Could be added as system messages on pair/key events. Phase 3 polish item.
- **FakeKeyboard**: screens.jsx:426-475. Custom dark keyboard overlay. Not implementable in Flutter (OS controls the keyboard). Design-only artifact.

## Ambiguities

- **Design's `T.surface` opacity**: `T.surface` is defined as `'#10151210'` (screens.jsx:9) — an 8-digit hex that could be RGBA with alpha `0x10` = ~6%. But `T.surfaceHi` is `'#141a17'` (6 digits, fully opaque). Unclear whether the trailing digits are alpha or a typo. Impl treats `surface` as `Color(0xFF101512)` (fully opaque). Recommended: keep fully opaque — transparent surfaces over the near-black background produce no visible difference.
- **Design's `T.bgDeep`**: defined as `'#06080706'` (screens.jsx:8) — 8 digits, low alpha. Never used in any screen. Impl does not include this token. No action needed.
- **AppToggle**: no design counterpart. The design shows a password input field; impl replaced it with a toggle per Task 8 decision. Not a delta — intentional architecture divergence.

## Recommended cut for Task 16

1. **Chat header status label**: change right-side from `CONNECTED`/`DISCONNECTED` to `ENCRYPTED`/`DECRYPTED`/status to match design's security-first intent (chat_screen.dart:146-149). High.
2. **Chat header sub-row**: replace `ENCRYPTED`/`PLAINTEXT` left label with `AES-256-GCM` or equivalent crypto label; move mode label to the status position, or add fingerprint placeholder (chat_screen.dart:157-160). High.
3. **Chat footer left text**: change from `ENCRYPTED`/`PLAINTEXT` to `AES-256-GCM` (chat_screen.dart:304-306). Medium.
4. **Home hero caret**: add blinking `Caret` widget after "No trace" text (home_screen.dart:108). High.
5. **Room setup step copy**: align "Agree on a shared phrase out of band" → "Agree on a password (optional)" or keep "phrase" but match format (room_setup_screen.dart:301). Medium.
6. **Room setup descriptive text**: restore "Then optionally set a nickname and a password" sentence (room_setup_screen.dart:279-280). Medium.
7. **Nickname help text on RoomSetup**: change from "visible only to you" to "Shown to your peer instead of PEER" to match design intent (room_setup_screen.dart:236-237). Medium.
8. **DiagCard line height**: increase from 1.6 to 1.9 to match design (home_screen.dart diagnostics; may need a one-off style override rather than changing the global `mono` token). Medium.
9. **Code slot empty placeholder**: add `_` underscore in empty code input slots (join_room_screen.dart). Low.
10. **Character counter in chat composer footer**: add `N / 4096` counter when composing (chat_screen.dart:309). Medium.
11. **Bubble sender labels uppercase**: re-add `.toUpperCase()` to sender labels to match design (message_bubble.dart:79). Low — was intentionally removed in Task 8b; needs Tech Lead decision.
12. **ScreenBase overlays** (vignette + scanlines + noise): add as a decorative layer in AppScaffold. Medium visual impact but significant implementation effort — recommend deferring to a dedicated pass.
