# Plan

_Updated by the Tech Lead chat before each task._

## Status

**Active task:** Phase 3 / Task 17a — **Fix 6 test timeouts introduced by Task 17**.

Task 17 closeout reported `flutter test`: 123 total (117 pass + 6 timeouts). The plan required all suites clean. 6 timeouts is a regression from Task 16's 102/102. Task 17a's only job is to identify those 6 tests and get the suite back to a fully clean run, with no test calling `pumpAndSettle` against an unbounded animation.

## Context

### Diagnosis hypothesis

Task 17 introduced two pieces of code that interact badly with Flutter widget tests:

1. **`Caret` component** — uses a `Timer.periodic` (or `AnimationController.repeat()`) that runs forever. Any test that calls `tester.pumpAndSettle()` on a widget tree containing a `Caret` will time out, because the framework treats the repeating timer as an unsettled animation.

2. **`Listenable.merge` in `main.dart`** — should be benign, but if a screen test instantiates the merged builder and the `ActivationController` schedules anything async beyond the awaited `load()`, that can also stall settle calls.

Hypothesis: all 6 timeouts are in widget tests that pump the new `Caret` directly or via a screen that contains it (HomeScreen hero block, ActivationScreen heading). The fix is at the test-call-site level (use bounded `pump(Duration)` calls instead of `pumpAndSettle`) **and possibly** at the component level (give `Caret` a way to be tick-paused in test environments, if needed).

This is a hypothesis — Part B confirms or refutes it. Don't act on the diagnosis until Part B finishes.

### Result.md phrasing — clean it up too

Task 17's result.md described the timeouts as *"pre-existing"*. They are not pre-existing — Task 16 closed at 102/102 clean. They are new failures introduced by Task 17. Task 17a fixes both the failures and the misleading phrasing in changelog.md / result.md if it's been propagated there.

### What Task 17a is NOT

- Not a redesign of `Caret`. The component is fine; only its testability needs a small lever.
- Not a refactor of any test that already passes. Touch only what's broken.
- Not a behavior change. The activation gate's runtime behavior is correct as shipped — Task 17a fixes the test infrastructure that proves it.

## Read First

- [CLAUDE.md](../CLAUDE.md)
- [docs/result.md](result.md) — Task 17 closeout (note the "117 pass + 6 timeouts" wording)
- [docs/changelog.md](changelog.md) — verify whether the 117/6 phrasing leaked into the changelog entry; if so, fix it as part of this task
- [docs/sessions.md](sessions.md)
- [lib/components/caret.dart](../lib/components/caret.dart) — Task 16 component, the prime suspect
- [lib/screens/activation_screen.dart](../lib/screens/activation_screen.dart) — Task 17 screen, contains a Caret
- [lib/screens/home_screen.dart](../lib/screens/home_screen.dart) — Task 16 caret usage
- [test/components/caret_test.dart](../test/components/caret_test.dart) — Task 16
- [test/screens/activation_screen_test.dart](../test/screens/activation_screen_test.dart) — Task 17
- [test/screens/](../test/screens/) — any other test files; the timeouts may not all be Caret-related

## Current Task

### Part A — Branching

1. Switch to `main`. Merge `task/activation-gate-v1` into `main` (no fast-forward).
2. Delete the local `task/activation-gate-v1` branch.
3. Branch off `main` as `task/test-timeout-fix`.

### Part B — Identify the 6 timeouts (read-only diagnosis)

Run `flutter test --reporter expanded` (or `--reporter json` and pipe through `jq` if more readable). Capture the full output. **Do not fix anything yet.**

For each timing-out test, record:

- File path + test name
- The widget tree it constructs
- Whether it contains a `Caret` (directly or via a screen)
- Whether it calls `pumpAndSettle()` (or `pumpAndSettle(Duration(...))` — even bounded settle can fail if the bound is too short)
- The exact error message Flutter prints (typically `pumpAndSettle timed out` after 10 minutes — for tests that genuinely hang, the runner kills them at the test-level timeout)

Output this table at the top of `result.md` so future-you can see what was actually broken. Don't compress the diagnosis — it's the load-bearing artifact for this task.

If the count doesn't equal 6 (e.g. 4 timeouts, or 8), say so explicitly. Trust the run, not the prior report.

### Part C — Decide the fix shape

Given the diagnosis, pick one of these patterns per test:

#### Pattern 1 — Bounded `pump`, no `pumpAndSettle`

For tests that just need to render the widget and inspect output:

```dart
await tester.pumpWidget(MyWidget());
await tester.pump(); // initial frame
// assertions
```

If the widget animates and you want to assert post-animation state, pump explicit durations:

```dart
await tester.pump(const Duration(milliseconds: 600));
```

Never `pumpAndSettle` against a `Timer.periodic` or `AnimationController.repeat()`. It will not settle.

#### Pattern 2 — Wrap the test body in `runAsync`

For tests that involve genuine async work (e.g. `SharedPreferences`-mocked controller flows), `runAsync` runs real-time async with a real clock. Combined with explicit `pump` calls, this avoids settle-loops:

```dart
await tester.runAsync(() async {
  await controller.activate(code);
});
await tester.pump();
```

#### Pattern 3 — Component-level test seam (only if needed)

If multiple tests need to render the Caret without its animation, add an opt-out to the component:

```dart
class Caret extends StatefulWidget {
  const Caret({
    super.key,
    required this.palette,
    this.color,
    this.height = 22,
    this.width = 10,
    @visibleForTesting this.disableAnimation = false,
  });
  final bool disableAnimation;
  // ...
}
```

The `_CaretState` checks `widget.disableAnimation` in `initState` and skips starting the timer/controller. The visible block stays rendered (so geometry tests still work) but never blinks.

This is a real production-code change, so use it only if Patterns 1–2 can't cleanly fix the affected tests. **Default to Patterns 1–2.** Don't add a test seam if you don't need it.

### Part D — Apply fixes

For each broken test from Part B, apply Pattern 1 or 2. If you reach for Pattern 3, justify it in result.md (which test, why bounded pump didn't work).

Constraints:
- Touch only the failing test files (and `caret.dart` if Pattern 3 applies).
- Do not change any production logic in ActivationController, ActivationScreen, HomeScreen, or main.dart.
- Do not change any *passing* test.

### Part E — Re-run and verify

1. `flutter test` — full pass, no timeouts. Count should be exactly 123 (or whatever Part B observed).
2. Run twice in a row to catch flakes — animation-driven tests are a classic flake source. If a test passes once and fails once, it's not fixed; revisit Part C and apply Pattern 3 to that specific test.
3. `flutter analyze` — clean. New `@visibleForTesting` annotations require `import 'package:meta/meta.dart';` if not already.
4. `npm test` — unchanged, 43.

### Part F — Documentation cleanup

In [docs/changelog.md](changelog.md), find the Task 17 entry. If it carried forward the misleading phrasing `117 pass + 6 pre-existing timeouts`, replace it with the truth:

```
- Tests: flutter 123/123 (Task 17 introduced 6 timeouts, fixed in Task 17a)
```

Or merge the entries — your choice. The reader of the changelog should not come away thinking those timeouts were preexisting.

In [docs/result.md](result.md) — this task's own result.md will overwrite the Task 17 file, so the misleading phrasing disappears naturally.

In [docs/sessions.md](sessions.md), do not add a new line for Task 17a — it's a closeout, not a new feature. Add a short addendum to the Task 17 session entry: `+ Task 17a: fixed 6 test timeouts from Caret animation interaction with pumpAndSettle.`

### Part G — Commit

One commit:

`fix: stabilize widget tests around blinking caret animation`

Stage only the test files and possibly `lib/components/caret.dart` (if Pattern 3 was used). Plus the doc files.

### Part H — Output (in your response and at the top of `result.md`)

- The diagnosis table from Part B (the 6 — or however many — broken tests, named).
- Which Pattern was used for each.
- Whether Pattern 3 (component-level seam) was added — yes/no, and why if yes.
- `flutter test` result on two consecutive runs (both must be clean).
- `flutter analyze` clean.
- `npm test` 43 unchanged.
- `git diff --name-only main..HEAD` — expect: test files only, possibly `caret.dart`, plus doc files. **No** changes to `activation_*.dart`, `main.dart`, `home_screen.dart`, `chat_*.dart`.

### Part I — Update docs/result.md, docs/sessions.md, docs/changelog.md

Per CLAUDE.md §4–§6, with the corrections in Part F.

## Specs

- Branch: `task/test-timeout-fix` (off `main`, after merging Task 17).
- One commit at the end.
- No new dependencies.
- No production behavior change. (`Caret`'s `disableAnimation` flag, if added, is a `@visibleForTesting` opt-out — production callers don't pass it, so behavior is unchanged.)
- Touch only failing tests + possibly `caret.dart`.

## Do NOT

- Do not weaken any test that currently passes — no removing assertions to dodge flakes.
- Do not change the activation flow or any other production logic.
- Do not add an arbitrary `await Future.delayed(...)` to make a flaky test pass — fix the cause (the unbounded pumpAndSettle), not the symptom.
- Do not extend the `flutter test` default timeout. The right number is "the test completes," not "the budget is bigger."
- Do not add new tests in this task. Closeout, not expansion.
- Do not push the branch.

## Commit Message

`fix: stabilize widget tests around blinking caret animation`
