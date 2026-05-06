# Plan

_Updated by the Tech Lead chat before each task._

## Status

**Active task:** Phase 3 / Task 16 — **UI polish pass: 5 fidelity fixes from the audit**.

Task 15 produced [docs/ui-audit.md](ui-audit.md) — 28 deltas with a 12-item recommended cut. Task 16 takes a smaller, opinionated cut: **5 changes**. The other 7 in the auditor's list either conflict with locked decisions, contradict crypto reality, or are deferred polish. Each rejection is documented at the bottom of this plan and must be repeated in `result.md`.

## Context

### The cut

| # | Delta | Source |
|---|---|---|
| 1 | Add blinking caret after "No trace" on HomeScreen | audit High #4 |
| 2 | Increase DiagCard line height from 1.6 to 1.9 | audit Medium |
| 3 | Render `_` underscore in empty code input slots | audit Low |
| 4 | Replace `TAP TO TYPE` footer text with `N / 4096` character counter while composing | audit Medium #10 |
| 5 | Drop "out of band" from RoomSetup step 03 copy | audit Medium #5 (compromise) |

### Why the other audit items are NOT in scope

The audit's recommended cut included 7 items I'm rejecting outright. Each rejection has a reason that should survive to future tasks so we don't keep re-litigating it. Carry these into `result.md` verbatim:

- **Chat header `CONNECTED`/`DISCONNECTED` → `ENCRYPTED`** (audit High #1): rejected. Peer-presence is useful information; "ENCRYPTED" is a tautology in password mode and a lie in open mode. Keep the existing label.
- **Chat header sub-row `ENCRYPTED`/`PLAINTEXT` → `AES-256-GCM`** (audit High #2): rejected. We use XChaCha20-Poly1305, not AES-GCM. The design's literal label is factually wrong for our cipher. Our `ENCRYPTED`/`PLAINTEXT` is accurate and mode-aware.
- **Chat footer `ENCRYPTED`/`PLAINTEXT` → `AES-256-GCM`** (audit Medium #3): same reason.
- **RoomSetup step 03 "phrase" → "password"** (audit Medium #5 first half): rejected. Locked Phase 2 constraint (sessions.md): _terminology is "phrase," not "password."_ Only the "out of band" simplification ships.
- **Restore "set a nickname and a password" sentence on RoomSetup** (audit Medium #6): rejected. Same locked-term issue, plus restoring it would imply password is mandatory, which it isn't.
- **Nickname help text "Shown to your peer instead of PEER"** (audit Medium #7): rejected. Nicknames are local-only today. The "LOCAL ONLY" badge says so. Adopting the design's copy would be a UX lie. Keep impl.
- **Bubble sender labels `.toUpperCase()`** (audit Low #11): rejected. Task 8b explicitly removed this. The lowercase form matches the project's quiet-terminal aesthetic. Locked.

The two deferred items (ScreenBase decorative overlays, expiry timer / fingerprint / system-message lifecycle copy) are also out of scope here. They are larger projects.

## Read First

- [CLAUDE.md](../CLAUDE.md)
- [docs/result.md](result.md) — Task 15 closeout
- [docs/sessions.md](sessions.md) — locked Phase 2 constraints, Phase 3 roadmap
- [docs/ui-audit.md](ui-audit.md) — the audit this task draws from
- [docs/changelog.md](changelog.md)
- [lib/screens/home_screen.dart](../lib/screens/home_screen.dart)
- [lib/screens/room_setup_screen.dart](../lib/screens/room_setup_screen.dart)
- [lib/screens/join_room_screen.dart](../lib/screens/join_room_screen.dart)
- [lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart)
- [lib/components/](../lib/components/) — note where existing pulse / blink animation lives (`pulse_dot.dart`)
- [lib/tokens/tokens.dart](../lib/tokens/tokens.dart)

## Current Task

### Part A — Branching

1. Switch to `main`. Merge `task/ui-audit` into `main` (no fast-forward).
2. Delete the local `task/ui-audit` branch.
3. Branch off `main` as `task/ui-polish-pass-1`.

### Part B — New component: `Caret`

Create [lib/components/caret.dart](../lib/components/caret.dart). A minimal blinking block cursor.

API:

```dart
class Caret extends StatefulWidget {
  const Caret({
    super.key,
    required this.palette,
    this.color,        // defaults to palette.accent
    this.height = 22,  // px — caller sets to match the surrounding text size
    this.width = 10,
  });
  // ...
}
```

Behavior:
- Solid filled rectangle, `color` (default `palette.accent`).
- Blinks on/off at ~530 ms cycle (close to the iOS system caret cadence). Use `AnimationController` with `repeat(reverse: false)` and a `StatusListener` that flips a `_visible` bool, or simpler: a periodic `Timer` with `setState`. Either works; pick the smaller one.
- Cancel the timer / dispose the controller in `dispose()`.
- No `padding`/`margin` props. Caller positions it.

Add a unit/widget test in `test/components/caret_test.dart`:
- Renders a `Container` with the requested width/height/color.
- After two pump-and-settles spanning 1100 ms, the visibility has toggled at least once. (Use `pumpAndSettle` only with a finite duration to avoid hanging on the repeating animation; or use `pump(Duration(milliseconds: 600))` deliberately.)
- Disposes cleanly without throwing.

### Part C — HomeScreen: blinking caret after "No trace"

In [lib/screens/home_screen.dart](../lib/screens/home_screen.dart):

1. Replace the `Text.rich` hero block with a `Row` (or `Wrap`) so a `Caret` sits flush after the accent-colored "No trace" text.
2. Caret height should match the heading font's caps height. With `AppTypography.heading` at 30px, set `height: 22` and `width: 10` as a starting point. If the visible block looks too tall against the cap line, drop to `height: 20`. Pick by reading the existing typography metrics, not by simulator.
3. Caret color: `palette.accent` (default — pass nothing).
4. The caret aligns with the **last** line of the hero text ("No trace"). Since the existing `Text.rich` uses `\n` line breaks, the cleanest restructure is:
   ```dart
   Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       Text('No accounts.', style: heading),
       Text('No history.', style: heading),
       Row(
         crossAxisAlignment: CrossAxisAlignment.end,
         children: [
           Text('No trace', style: heading.copyWith(color: p.accent)),
           const SizedBox(width: AppSpacing.sm - 4),
           Caret(palette: p),
         ],
       ),
     ],
   )
   ```
   (Use whichever spacing token gets the caret about 4–6 px right of the text — eyeball the token math, this isn't load-bearing.)

### Part D — DiagCard line height

In [lib/screens/home_screen.dart](../lib/screens/home_screen.dart), in `_DiagRow.build`:

1. Override the line height locally on both `Text.rich` and the trailing value `Text` widget. Use `style.copyWith(height: 1.9)` on the styles passed in.
2. Do **not** change `AppTypography.mono` in `tokens.dart` — that token is used elsewhere (HomeScreen's "Rooms exist only while open…" paragraph and others). DiagCard is the only place that wants the looser leading.
3. Verify visually-equivalent output across the four diag rows (entropy / transport / storage / identity). They each should now read with one extra line-height step's breathing room.

### Part E — Code slot empty placeholder

In [lib/screens/join_room_screen.dart](../lib/screens/join_room_screen.dart) `_buildCodeSlots`:

1. When `_codeControllers[idx].text` is empty (i.e. `!hasFill`), the `TextField` should show `_` as the hint character. Implementation: add `decoration.hintText: '_'` and a `hintStyle` that uses `palette.textMuted` at the same fontSize as the filled style (22) but `fontWeight: FontWeight.w400` (lighter than the bold filled state).
2. Hint disappears as soon as the user types — the existing `controller.text` change already triggers `setState`.
3. The hint must not interfere with the auto-advance focus chain or the backspace-to-previous-slot behavior.

### Part F — Character counter in chat composer footer

In [lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart):

1. The right-side footer micro-text currently switches between `'TAP TO TYPE'` (default) and `'TAP ANYWHERE TO EXIT'` (peer-left/mismatch).
2. Add a third state: when the input has focus **and** non-empty text **and** the chat is not in an exit state, show `'${_inputController.text.length} / 4096'`.
3. Implementation needs the screen to rebuild on input change. Add a listener on `_inputController` in `initState` (`_inputController.addListener(_onInputChanged)` → `setState(() {})`), and remove it in `dispose`. Don't forget to dispose.
4. Color stays `palette.textMuted` until the count exceeds, say, 3500 — at which point switch to `palette.warning`. Reason: the server caps at 4096 chars and a hard cap mid-send is hostile; warning the user as they approach is friendlier. Use a private const `static const _composerSoftLimit = 3500;` so it's tunable.
5. Edge case: `_peerLeft` and `mismatchDetected` continue to win. The counter is the lowest-priority state. Order:
   - `_peerLeft` → `'TAP ANYWHERE TO EXIT'`
   - `mismatchDetected` → `'TAP ANYWHERE TO EXIT'`
   - input has text → `'N / 4096'`
   - else → `'TAP TO TYPE'`

### Part G — RoomSetup step 03 copy

In [lib/screens/room_setup_screen.dart](../lib/screens/room_setup_screen.dart) line ~301:

Replace `'Agree on a shared phrase out of band'` with `'Agree on a shared phrase'`.

That's the entire change. Do not adjust the surrounding `_StepRow` layout.

### Part H — Tests

New: [test/components/caret_test.dart](../test/components/caret_test.dart) — per Part B.

Existing tests:
- `test/screens/chat_screen_test.dart`: extend with a case for the character counter — pump some input via the controller, verify footer shows `'N / 4096'`. Verify priority order: when `mismatchDetected == true`, footer reads `'TAP ANYWHERE TO EXIT'` regardless of input contents.
- `test/screens/room_setup_screen_test.dart` (or wherever the step-row test lives): no test required for the Part G copy change — too granular.
- Adjust any tests that assert on the old "out of band" string. Search for it; expect zero or one hit.

If a HomeScreen test exists, optionally extend with a `find.byType(Caret)` assertion. If no HomeScreen test exists, do not create one for this task — the caret is visually verifiable, not behaviorally critical.

### Part I — `flutter analyze`, `flutter test`, `npm test`

All clean. Flutter test count grows from 97 (expect ~99–100 — caret tests + counter test). Server tests stay at 43.

### Part J — Commit

One commit:

`feat: ui polish — blinking caret, line height, code slot hints, char counter`

### Part K — Output (in your response and at the top of `result.md`)

- Confirm `flutter analyze` clean.
- `flutter test` count vs. Task 15's 97.
- `npm test` count (expect unchanged: 43).
- `git diff --name-only main..HEAD` — expect: new `caret.dart`, new `caret_test.dart`, modified `home_screen.dart`, `join_room_screen.dart`, `chat_screen.dart`, `room_setup_screen.dart`, `chat_screen_test.dart`, plus the doc files.
- **The rejection ledger** — copy the 7 rejected items from this plan into result.md verbatim with their reasons. This is the load-bearing artifact: future polish tasks should not re-propose these.
- Note whether any tests had to be updated for the "out of band" string.

### Part L — Update docs/result.md, docs/sessions.md, docs/changelog.md

Per CLAUDE.md §4–§6.

In sessions.md, do **not** tick "Final terminal-UI pass against design" — Task 16 is one polish pass, not the *final* pass. Update the existing audit-pointer line to mention Task 16's commit hash or branch, e.g.:

`audit at docs/ui-audit.md (Task 15 · 2026-05-06); first polish pass shipped via task/ui-polish-pass-1 (Task 16)`.

Future polish work (decorative overlays, more aggressive caret usage, etc.) is intentionally left for later passes.

## Specs

- Branch: `task/ui-polish-pass-1` (off `main`, after merging Task 15).
- One commit at the end.
- One new component (`Caret`), one new test file, no new dependencies, no new tokens, no new screens.
- All five fixes from the cut, no others.

## Do NOT

- Do not implement any of the 7 rejected items, even if they look easy. The reasons live in this plan; revisit only via a fresh Tech Lead decision.
- Do not change `AppTypography.mono` or any other global typography token. Local `copyWith` only.
- Do not reuse the Caret in code-input slots, RoomSetup, or the composer in this task — the audit notes that the design uses Caret in those places too, but expanding usage is a separate task. Keep the surface change tight.
- Do not log key bytes, plaintexts, ciphertexts, or any portion thereof.
- Do not raise the server's 4096 cap or change `_composerSoftLimit` based on speculation.
- Do not push the branch.

## Commit Message

`feat: ui polish — blinking caret, line height, code slot hints, char counter`
