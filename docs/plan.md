# Plan

_Updated by the Tech Lead chat before each task._

## Status

**Active task:** Phase 3 / Task 15 — **UI fidelity audit (read-only delta list)**.

This task produces a single artifact: `docs/ui-audit.md` — a per-screen, per-component delta list comparing the implemented Flutter UI against the design reference in `docs/design/`. **No code changes.** Task 16 will use this list to drive an actual polish pass.

Reason for splitting it this way: a pixel-polish pass without an explicit list of what's wrong is open-ended — easy to over-fix, easy to miss things, hard to review. An audit-first task makes the scope of Task 16 reviewable up front.

## Context

### Design reference

`docs/design/` contains the Claude Design handoff bundle (Task 1):

- `Secret Chat.html` — entry point (small, 30 lines)
- `screens.jsx` — all five screen layouts (536 lines, the load-bearing file)
- `app.jsx` — top-level composition (145 lines)
- `design-canvas.jsx`, `tweaks-panel.jsx`, `ios-frame.jsx` — decorative wrappers, *probably* not relevant
- `chat1.md` — design conversation transcript (253 lines, may contain intent the JSX doesn't show)
- `readme.md` — handoff instructions

The design files are HTML/CSS/JSX prototypes. The audit's job is to compare *visual output* (colors, spacing, typography, border treatments, copy, layout structure), not source-code structure. Differences in code organization between the prototype and the Flutter implementation are not deltas.

### Implemented surface

Five screens (`lib/screens/`):
- `home_screen.dart`
- `room_setup_screen.dart`
- `join_room_screen.dart`
- `chat_screen.dart`
- `settings_screen.dart`

Nine components (`lib/components/`):
- `app_scaffold.dart`, `app_button.dart`, `app_text_field.dart`, `app_text.dart`, `app_toggle.dart`, `message_bubble.dart`, `pulse_dot.dart`, `room_code_display.dart`, `system_message.dart`

Five palettes (`lib/theme/palettes/`): Mint (default), Ice, Indigo, Sand, Lime.

### Audit categories

For each screen, classify deltas under these categories. Skip categories that don't apply:

1. **Layout structure** — order of sections, presence/absence of regions, alignment, vertical rhythm.
2. **Spacing** — paddings, margins, gaps. Reference `lib/tokens/tokens.dart` `AppSpacing` values; flag deviations from design that aren't already in the spacing tokens.
3. **Typography** — font weight, size, letter-spacing, line height, casing (uppercase vs sentence case vs lowercase).
4. **Colors** — palette slot used (e.g. `textMuted` vs `textSecondary`), border colors, accent usage, warning/error tones.
5. **Borders & radii** — border width, border-radius values, divider presence.
6. **Copy** — exact strings (placeholders, labels, micro-text, system messages, button labels). The biggest risk: stale copy left over from earlier tasks.
7. **Iconography / glyphs** — `›`, `‹`, `—`, `// HEADER`, `[locked]`, etc. Verify the design uses the same glyphs.
8. **Component fidelity** — for each component, list the props/states the design shows vs. what the implementation supports.
9. **Animations / motion** — pulses, fades, transitions. The design likely calls some out; flag anything missing.
10. **Responsive / safe-area handling** — only flag if the design explicitly addresses it.

For each delta, classify severity:
- **High** — visibly wrong (e.g. a section in the wrong order, a color that's clearly different, copy that's misleading).
- **Medium** — noticeable on a careful side-by-side (e.g. spacing off by one token step, a typography weight mismatch).
- **Low** — only visible to a designer (e.g. a 1px border vs 0.5px, a letter-spacing nudge).

### What the audit must NOT do

- Must not change any code. Strict read-only task.
- Must not invent features. If the design shows a feature not yet implemented, that's a *feature gap* — list it under a separate "Unimplemented from design" section, not as a delta to fix.
- Must not produce a list of "nice-to-haves" or speculative improvements. Only deltas vs. the reference.
- Must not propose theme/palette changes — palettes are locked from Task 2.
- Must not include screenshots, simulator runs, or anything that requires a device. The design reference is plain text; the implementation is plain text; the comparison is text-to-text.

### Why this is doable from source alone

Both sides are readable text:
- Design: JSX/HTML with className strings and inline values.
- Implementation: Flutter widgets with explicit `EdgeInsets`, `TextStyle`, `BorderRadius`, palette slot names.

The mapping is mechanical for most categories. Where it isn't (e.g. a CSS class without a token mapping), record the ambiguity and move on — Task 16 will resolve it with a judgment call.

## Read First

- [CLAUDE.md](../CLAUDE.md)
- [docs/result.md](result.md) — Task 14 closeout
- [docs/sessions.md](sessions.md) — Phase 3 roadmap; this is the third Phase 3 task
- [docs/changelog.md](changelog.md)
- [docs/design/readme.md](design/readme.md) — handoff instructions
- [docs/design/Secret Chat.html](design/Secret%20Chat.html) — entry point, read in full
- [docs/design/screens.jsx](design/screens.jsx) — read in full
- [docs/design/app.jsx](design/app.jsx) — read in full
- [docs/design/chat1.md](design/chat1.md) — design intent / decisions, skim then deep-read any sections that look like landed decisions
- [lib/tokens/tokens.dart](../lib/tokens/tokens.dart) — `AppSpacing`, `AppRadii`, `AppTypography`, `AppPalette`
- [lib/theme/palettes/](../lib/theme/palettes/) — five palette files
- All five screens in [lib/screens/](../lib/screens/)
- All nine components in [lib/components/](../lib/components/)

Do **not** read `docs/design/design-canvas.jsx` or `tweaks-panel.jsx` or `ios-frame.jsx` unless the audit specifically calls for it — those are likely Claude-Design wrapper chrome, not app design.

## Current Task

### Part A — Branching

1. Switch to `main`. Merge `task/session-management` into `main` (no fast-forward).
2. Delete the local `task/session-management` branch.
3. Branch off `main` as `task/ui-audit`.

### Part B — Read the design reference

Read in this order:

1. `docs/design/readme.md` (orientation)
2. `docs/design/Secret Chat.html` (entry point — small, 30 lines)
3. `docs/design/app.jsx` (composition)
4. `docs/design/screens.jsx` (the meat)
5. `docs/design/chat1.md` — extract any landed decisions that are not visible in the JSX (e.g. copy choices, ordering, intent behind specific choices)

Build a mental model of: what screens exist in the design, how they relate, what shared elements (top bar, footer micro-text, dividers) appear across them.

### Part C — Walk the implementation

Read in this order:

1. `lib/tokens/tokens.dart` (the tokens — your vocabulary for the audit)
2. The default palette file `lib/theme/palettes/mint.dart` (audit references this; cross-check Ice/Indigo/Sand/Lime only if the design explicitly varies by theme)
3. All nine components, in alphabetical order
4. All five screens, in this order: home, room_setup, join_room, chat, settings

Note for each screen: what the user sees, what dynamic states it has (e.g. RoomSetup has pre-generation and post-generation states; Chat has paired / mismatch / peer-left states).

### Part D — Produce `docs/ui-audit.md`

Structure of the file (use this exact skeleton):

```markdown
# UI Fidelity Audit

_Generated: <ISO date>_
_Audited against: docs/design/screens.jsx + chat1.md_
_Auditor: Claude Code (Task 15)_

## Summary

- Screens audited: 5
- Components audited: 9
- Total deltas: <N>
- High severity: <N>
- Medium: <N>
- Low: <N>

## Method

One paragraph: what was compared, what was excluded, where ambiguities were treated as "ambiguous" rather than as deltas.

## Screens

### Home

#### High
- <delta> — design says X, implementation does Y. Reference: design/screens.jsx:<line>; impl: lib/screens/home_screen.dart:<line>.

#### Medium
- ...

#### Low
- ...

### Room Setup
…

### Join Room
…

### Chat
…

### Settings
…

## Components

### AppButton
- <delta> ...

### AppTextField
- ...

(repeat for all nine — only include sections that have deltas; omit clean components but list them in a "Clean: AppX, AppY" line at the end of the Components section)

## Cross-cutting

Things that span screens (e.g. a footer micro-text inconsistency, a glyph used differently in two places). Each item should reference both screens it appears on.

## Unimplemented from design

Features visible in the design that have not been implemented yet. **Do not** list these as deltas — separate section. Each entry: what the design shows + which file/line, and a one-sentence note on whether this looks like a Phase 3 polish item or a deeper feature.

## Ambiguities

Cases where the design reference is unclear or contradicts itself. Each: what was unclear, what choice the implementation made, and a recommended interpretation (one sentence).

## Recommended cut for Task 16

A short ordered list (5–15 items) — the deltas the auditor recommends fixing first in a single commit. Mix High and Medium; skip Low unless they're trivial. This is the auditor's suggestion, not a contract — the Tech Lead chooses the actual cut.
```

Style guide for entries:

- Each delta is a single bullet, 1–2 sentences.
- Always include a file+line reference for both sides where possible.
- Use exact strings in quotes when comparing copy ("YOUR PHRASE" vs "type the phrase…").
- Pixel-counting: if the design uses raw pixel values that don't map to existing `AppSpacing` tokens, note both numbers (e.g. "design uses 18px, impl uses AppSpacing.lg = 16px").
- Don't editorialize. "Design says X, impl does Y." is enough; the recommendation goes only in the "Recommended cut" section.

### Part E — `flutter analyze`, `flutter test`, `npm test`

Run all three to confirm no regression from the merge in Part A. Counts unchanged from Task 14 (97 / 43 / clean).

### Part F — Commit

One commit:

`docs: ui fidelity audit — delta list for task 16`

Stage only `docs/ui-audit.md` plus the documentation updates. No source files should appear in the diff.

### Part G — Output (in your response and at the top of `result.md`)

- `docs/ui-audit.md` line count and total delta count by severity.
- Screens that came out clean (zero deltas) vs. dirty.
- Components that came out clean.
- The recommended-cut list verbatim (or a clear pointer to the section in `ui-audit.md`).
- Confirm no source files changed: `git diff --name-only main..HEAD` should show only `docs/` files.
- `flutter analyze` clean, `flutter test` 97, `npm test` 43 unchanged.

### Part H — Update docs/result.md, docs/sessions.md, docs/changelog.md

Per CLAUDE.md §4–§6.

In sessions.md, do **not** tick "Final terminal-UI pass against design" yet — Task 15 is preparation, not the pass itself. Add a one-line note under that bullet: `audit at docs/ui-audit.md (Task 15 · 2026-05-06)`.

## Specs

- Branch: `task/ui-audit` (off `main`, after merging Task 14).
- One commit at the end.
- One new file: `docs/ui-audit.md`.
- Zero source-file changes.
- No new tests; no new tokens; no new dependencies.

## Do NOT

- Do not change any source file.
- Do not add screenshots or run a simulator.
- Do not propose new features. Unimplemented design surfaces go in the "Unimplemented from design" section as a list, not as deltas.
- Do not propose palette/theme changes.
- Do not produce more than ~50 deltas total. If the count is creeping past that, you're being too granular — collapse Low-severity items into a single "many small typography nudges" entry with examples.
- Do not push the branch.

## Commit Message

`docs: ui fidelity audit — delta list for task 16`
