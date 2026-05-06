# Plan

_Updated by the Tech Lead chat before each task._

## Status

**Active task:** Phase 3 / Task 14 — **Smooth session management: termination reason + foreground/background hardening**.

Task 13 fixed the *pre-pairing* connection failure modes. Task 14 fixes the *post-pairing* ones.

The single user-visible bug: when the chat session ends, ChatScreen always shows `peer disconnected — room closed`, regardless of whether the peer actually left or *we* lost connection (network flip, OS killing the socket while backgrounded, server crash). That's misleading.

The single behavioral question: should backgrounding the app close the session? Today's policy (Task 7b decision) is **no — only `detached` closes**. Task 14 confirms this and writes it down explicitly so future tasks don't drift.

## Context

### What ChatClient knows about *why* it closed

Today, three code paths flip `state` to `closed`:

1. [chat_client.dart:90-92](../lib/network/chat_client.dart) — `PeerLeftMsg` arrives. The peer left cleanly (their app sent a close, or the server saw their socket die and notified us as the survivor).
2. [chat_client.dart:184-188](../lib/network/chat_client.dart) — `_onError` fires. Stream-level error mid-session. Sets `_lastError = 'connection_error'`.
3. [chat_client.dart:190-194](../lib/network/chat_client.dart) — `_onDone` fires. Stream closed unexpectedly. Sets `_lastError = 'connection_lost'`.

Path 1 does **not** set `_lastError` and immediately calls `close()`, which resets `_lastError = null`. So ChatScreen sees `state == closed` and `lastError == null` for case 1, and `lastError != null` for cases 2/3 — but only briefly, until `close()` runs in those paths too.

We need ChatScreen to make the distinction reliably and survive the `close()` reset.

### The fix: a `ChatTerminationReason`

Introduce a small enum on `ChatClient`:

```dart
enum ChatTerminationReason { peerLeft, connectionLost }
```

`peerLeft` covers case 1. `connectionLost` covers cases 2 *and* 3 — the user-visible distinction between "stream errored" and "stream done unexpectedly" is meaningless and we don't want two separate copy strings for them.

The reason is set **before** the `closed` state transition that ChatScreen reacts to. It is **preserved** through `close()` and only cleared on the *next* fresh `createRoom` / `joinRoom`. Rationale: ChatScreen reads it after observing `state == closed`, then exits to Home — the user-initiated exit (tapping back / `_goHome`) calls `close()` to tear down, but the screen has already captured what it needs.

Three additional cases to handle correctly:

- **User taps back** while paired (`_goHome` → `close()` → `state == idle`). This is *not* a termination from the user's perspective — they chose to leave. `_terminationReason` stays null.
- **`detached` lifecycle** (app force-quit). `close()` runs. We don't get to render anything, so the reason value doesn't matter.
- **Pre-pairing close()** (e.g. user backs out of RoomSetup before generating). `_terminationReason` stays null.

The rule: only the three internal close-triggering paths (`PeerLeftMsg`, `_onError`, `_onDone`) set `_terminationReason`. Explicit user-initiated `close()` does not.

### Lifecycle policy — locked

Confirm and document. No code change to lifecycle handling.

- `paused` (backgrounding via app switcher, lock screen, notification shade): **no close**. Session preserved.
- `inactive` (incoming call, control center swipe): **no close**.
- `hidden` (added in newer Flutter): **no close**.
- `detached` (process going away — force quit, OS reclaim): **close immediately**.

The reason `paused` is preserved: it's a routine UX gesture and breaking the chat there is hostile. The OS or server will notice if the app stays backgrounded long enough that the socket dies — the existing 30s server heartbeat will eventually fire `peer_left` to the surviving peer, and on resume the local app sees `state == closed` with `_terminationReason == connectionLost`. That is correct and adequate.

### What we are NOT doing

- Not adding auto-reconnect post-pairing. Locked constraint.
- Not extending the wire protocol. The reason is purely client-local.
- Not adding heartbeat/ping logic on the client. Server already heartbeats every 30s.
- Not changing the policy. `paused` stays a no-op.
- Not touching the design / theme. The terminal-UI polish pass is a separate task.
- Not adding any new screens or components. Copy + state field only.

## Read First

- [CLAUDE.md](../CLAUDE.md)
- [docs/result.md](result.md) — Task 13 closeout
- [docs/sessions.md](sessions.md) — Phase 2 locked constraints + Phase 3 roadmap
- [docs/changelog.md](changelog.md)
- [lib/main.dart](../lib/main.dart) — lifecycle observer (verify, don't change)
- [lib/network/chat_client.dart](../lib/network/chat_client.dart) — `_onData` PeerLeftMsg case, `_onError`, `_onDone`, `close()`
- [lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart) — `_onClientChanged`, post-pairing drop UX, `peer_left` system message
- [test/network/chat_client_test.dart](../test/network/chat_client_test.dart)
- [test/screens/chat_screen_test.dart](../test/screens/chat_screen_test.dart)

## Current Task

### Part A — Branching

1. Switch to `main`. Merge `task/connect-error-ux` into `main` (no fast-forward).
2. Delete the local `task/connect-error-ux` branch.
3. Branch off `main` as `task/session-management`.

### Part B — `ChatTerminationReason` enum + state field

In [lib/network/chat_client.dart](../lib/network/chat_client.dart):

1. At the top of the file (above `ChatConnectionState`), add:
   ```dart
   enum ChatTerminationReason { peerLeft, connectionLost }
   ```
2. Add private field `ChatTerminationReason? _terminationReason;` and public getter `ChatTerminationReason? get terminationReason => _terminationReason;`.
3. Set the reason at the three sites:
   - In `_onData`'s `PeerLeftMsg` case, set `_terminationReason = ChatTerminationReason.peerLeft;` **before** `_setState(closed)`.
   - In `_onError`, set `_terminationReason = ChatTerminationReason.connectionLost;` **before** `_setState(error)`.
   - In `_onDone`, set `_terminationReason = ChatTerminationReason.connectionLost;` **before** `_setState(closed)`.
4. **Do not** clear `_terminationReason` in `close()`. The field survives close.
5. **Do** clear `_terminationReason` at the top of `createRoom` and `joinRoom` (a fresh attempt starts with no reason). One line each.
6. Do not include the reason in any log line. (No new log lines anywhere.)

### Part C — ChatScreen: distinguish peer-left vs connection-lost

In [lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart):

1. Replace the existing single boolean `_peerLeft` with a typed reason that mirrors the client. Two options — pick whichever is cleaner with the existing scaffolding:
   - **Option A (simpler)**: keep `_peerLeft` as a boolean (true when terminated for *any* reason) plus read `widget.chatClient.terminationReason` directly when rendering copy. Less state, single source of truth for the reason.
   - **Option B**: store the reason locally as `ChatTerminationReason? _terminatedReason` and snapshot it in `_onClientChanged` when transitioning to closed.

   Option A is preferred — fewer fields, no risk of drift. The only downside is reading from `widget.chatClient` after a hypothetical further state change, but `terminationReason` is monotonic (once set, only cleared on a fresh `createRoom`/`joinRoom` which won't happen from this screen).
2. The `peer disconnected — room closed` SystemMessage at the bottom of the message list (currently rendered when `_peerLeft == true`) becomes:
   - `peerLeft` → `peer disconnected — room closed`
   - `connectionLost` → `connection lost — room closed`
   - reason `null` (defensive) → `room closed`
3. The footer micro-text on the right keeps the same `TAP ANYWHERE TO EXIT` treatment in all three cases.
4. `_goHome` is unchanged (calls `chatClient.close()` and pops to first route).

### Part D — Lifecycle policy: comment + test, no code change

In [lib/main.dart](../lib/main.dart):

1. Replace the existing one-line comment above `didChangeAppLifecycleState` with:
   ```dart
   // Lifecycle policy:
   //   paused / inactive / hidden  →  no-op (routine backgrounding preserves the session)
   //   detached                    →  close (process going away — wipe everything)
   ```
2. Branch only on `AppLifecycleState.detached`. Do not handle the other states. (This is the current code — verify the diff is just the comment.)
3. Do not add a "background timeout" or any timer-based auto-close. Out of scope.

### Part E — Tests

In [test/network/chat_client_test.dart](../test/network/chat_client_test.dart), add a group `terminationReason`:

- After `PeerLeftMsg` arrives: `terminationReason == ChatTerminationReason.peerLeft`. State is `closed`.
- After stream error mid-session: `terminationReason == ChatTerminationReason.connectionLost`.
- After stream closes unexpectedly mid-session: `terminationReason == ChatTerminationReason.connectionLost`.
- After explicit user `close()` (no preceding internal trigger): `terminationReason == null`.
- `terminationReason` survives `close()` (set, then call close — still set).
- `terminationReason` is cleared on next `createRoom` and on next `joinRoom`.
- Pre-pairing `close()` (user backs out before pairing): `terminationReason == null`.

In [test/screens/chat_screen_test.dart](../test/screens/chat_screen_test.dart), extend with three widget tests:

- Termination via `peerLeft` renders the system message `peer disconnected — room closed`.
- Termination via `connectionLost` renders the system message `connection lost — room closed`.
- Composer is disabled and footer reads `TAP ANYWHERE TO EXIT` in both cases (parameterize if your test framework supports it; two separate tests is also fine).

In [test/main_lifecycle_test.dart](../test/main_lifecycle_test.dart) (new file, or wherever lifecycle tests live — check the existing tree first; if no lifecycle test file exists, create this one):

- Sending `AppLifecycleState.paused` to the observer does **not** call `chatClient.close()`.
- Sending `AppLifecycleState.inactive` does not call `close()`.
- Sending `AppLifecycleState.hidden` does not call `close()`.
- Sending `AppLifecycleState.detached` calls `close()` exactly once.

If wiring a real `WidgetsBinding` lifecycle test is too heavy, alternative: refactor the lifecycle decision into a small pure function `bool shouldCloseOnLifecycle(AppLifecycleState state) => state == AppLifecycleState.detached;` and unit-test that. The function lives in `main.dart` (or a tiny new `lib/lifecycle.dart` if you prefer separation — pick the smaller diff). Whichever path you pick, the test must lock the policy, not just trace the existing code.

### Part F — `flutter analyze`, `flutter test`, `npm test`

All clean. Flutter test count grows from 81. Server tests stay at 43.

### Part G — Commit

One commit:

`feat: session management — termination reason + lifecycle policy locked`

### Part H — Output (in your response and at the top of `result.md`)

- Confirm `flutter analyze` clean.
- `flutter test` count vs. Task 13's 81.
- `npm test` count (expect unchanged: 43).
- `git diff --name-only main..HEAD` — expect: `chat_client.dart`, `chat_screen.dart`, `main.dart` (comment only), `chat_client_test.dart`, `chat_screen_test.dart`, possibly new lifecycle test file, plus the doc files.
- One sentence confirming the lifecycle policy is unchanged behaviorally (only the comment changed).

### Part I — Update docs/result.md, docs/sessions.md, docs/changelog.md

Per CLAUDE.md §4–§6.

In sessions.md, tick:
- [x] Smooth session management (foreground/background, network drops)

Phase 3 remaining after this task: terminal-UI pass, app store assets, release builds.

## Specs

- Branch: `task/session-management` (off `main`, after merging Task 13).
- One commit at the end.
- No new dependencies.
- No protocol changes.
- No new components, screens, or tokens.
- No timer-based auto-close.

## Do NOT

- Do not auto-reconnect post-pairing. Locked.
- Do not extend the wire protocol with a "leaving" signal. Server already broadcasts `peer_left` on socket close.
- Do not log termination reasons.
- Do not change `paused`/`inactive`/`hidden` lifecycle handling — those stay no-ops.
- Do not introduce a "session timeout" or background-after-N-minutes close.
- Do not push the branch.

## Commit Message

`feat: session management — termination reason + lifecycle policy locked`
