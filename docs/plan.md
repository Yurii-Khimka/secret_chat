# Plan

_Updated by the Tech Lead chat before each task._

## Status

**Active task:** Phase 3 / Task 13 — **Connection error handling + retry UX**.

This is the first Phase 3 task. Phase 2 closed all security objectives; Phase 3 is about polish — making the failure modes legible.

Today the app handles the *happy* network path well, but the *unhappy* paths leak through:

- **No connect timeout.** `WebSocketChannel.connect` + `await channel.ready` can stall indefinitely if the server is unreachable, the network has a black hole, or DNS hangs. The user sees `Connecting…` forever.
- **RoomSetupScreen has no error surface.** When `chatClient.state == ChatConnectionState.error` while generating, the screen flips `_generating = false` and rebuilds — the button reverts to `Generate Code` with no explanation, no retry guidance, no error string. Pure dead-end.
- **RoomSetupScreen, post-code, has no drop UX.** If the WS connection dies after the code is generated but before a peer joins, the screen still says `WAITING FOR PEER` indefinitely. The user has no signal that the connection is gone.
- **Error code mapping is duplicated and inconsistent** between [join_room_screen.dart](../lib/screens/join_room_screen.dart) (a `_errorMessages` map) and [room_setup_screen.dart](../lib/screens/room_setup_screen.dart) (no mapping at all).

Task 13 fixes those four. It does **not** add auto-reconnect — Phase 2's locked constraint is *"Either disconnect destroys room, survivor gets peer_left"*, so once paired, drops are terminal and only need a clean exit. Auto-reconnect is meaningful only for the *pre-pairing* phase, and even there we go with manual retry rather than silent retry — the user should always know there was a connection issue.

## Context

### Connect-timeout placement

`ChatClient._connect()` is the only place that calls `WebSocketChannel.connect`. A reasonable bound is **8 seconds** — long enough to absorb slow handshakes and TLS negotiation on bad mobile networks, short enough that the user gives up at roughly the same time the app does.

Implementation: race `channel.ready` against `Future.delayed(Duration(seconds: 8))`. If the timer wins, set `_lastError = 'connect_timeout'` and `_setState(error)`, and `channel.sink.close()` defensively (the half-open channel must not leak).

### Error code surface

Current `_lastError` values produced by `ChatClient`:

- `connection_failed` — `WebSocketChannel.connect` threw before `ready`.
- `connection_error` — stream emitted error mid-session.
- `connection_lost` — stream closed unexpectedly.
- `bad_message` — local code-format check failed before sending `join_room`.
- Plus all server-supplied codes (`not_found`, `room_full`, `cannot_join_own`, `already_in_room`, `not_in_room`, `not_paired`, `bad_request`).

We are adding **one new code**: `connect_timeout`. No other code surface changes.

### The retry model

Manual, explicit, single-tap. No exponential backoff, no auto-attempt. The user sees an error message and a button labeled `Retry`. Tapping `Retry` resets local state (`chatClient.close()` → fresh connect attempt). Code-input fields and nickname survive the retry; the user does not have to re-enter them.

### What stays the same

- ChatScreen post-pairing behavior is unchanged. `peer_left` / `connection_lost` after pairing → existing exit-to-home flow via the `_peerLeft` UI. (Verify, don't rebuild.)
- HomeScreen has no connection logic; nothing to change there.
- Server is unchanged.
- No new dependencies, no new components, no new tokens.

## Read First

- [CLAUDE.md](../CLAUDE.md)
- [docs/result.md](result.md) — Task 12 closeout
- [docs/sessions.md](sessions.md) — Phase 2 locked constraints + Phase 3 roadmap
- [docs/changelog.md](changelog.md)
- [lib/network/chat_client.dart](../lib/network/chat_client.dart) — `_connect`, `_onError`, `_onDone`, error codes
- [lib/screens/room_setup_screen.dart](../lib/screens/room_setup_screen.dart) — `_onClientChanged`, error path
- [lib/screens/join_room_screen.dart](../lib/screens/join_room_screen.dart) — `_errorMessages` map (move to shared)
- [lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart) — verify post-pairing drop behavior
- [test/network/chat_client_test.dart](../test/network/chat_client_test.dart)

## Current Task

### Part A — Branching

1. Switch to `main`. Merge `task/server-logging-audit` into `main` (no fast-forward).
2. Delete the local `task/server-logging-audit` branch.
3. Branch off `main` as `task/connect-error-ux`.

### Part B — Connect timeout in `ChatClient._connect`

In [lib/network/chat_client.dart](../lib/network/chat_client.dart):

1. Add `static const Duration _connectTimeout = Duration(seconds: 8);` (private constant on ChatClient).
2. Replace the body of `_connect()`:
   ```dart
   final channel = WebSocketChannel.connect(ServerConfig.serverUri);
   try {
     await channel.ready.timeout(_connectTimeout);
   } on TimeoutException {
     try { await channel.sink.close(); } catch (_) {}
     _lastError = 'connect_timeout';
     _setState(ChatConnectionState.error);
     return;
   } catch (e) {
     try { await channel.sink.close(); } catch (_) {}
     _lastError = 'connection_failed';
     _setState(ChatConnectionState.error);
     return;
   }
   _channel = channel;
   _subscription = channel.stream.listen(_onData, onError: _onError, onDone: _onDone);
   ```
   Two notes:
   - The pre-existing `if (_channel != null) return;` guard at the top stays.
   - The `setState(connecting)` call before this block stays.
   - Importing `dart:async` for `TimeoutException` is required if not already imported.
3. Do not log the failure path. (No new log lines anywhere.)

### Part C — Centralize error-code → message mapping

Create [lib/network/error_messages.dart](../lib/network/error_messages.dart) (new file). Single export:

```dart
const Map<String, String> kConnectionErrorMessages = {
  // Server-supplied codes
  'not_found':       '[ERROR] no such room',
  'room_full':       '[ERROR] room is full',
  'bad_message':     '[ERROR] invalid code',
  'bad_request':     '[ERROR] bad request',
  'cannot_join_own': "[ERROR] that's your own code",
  'already_in_room': '[ERROR] already in a room',
  'not_in_room':     '[ERROR] not in a room',
  'not_paired':      '[ERROR] not paired with a peer',
  // Client-side connection codes
  'connection_failed': '[ERROR] could not reach server',
  'connection_error':  '[ERROR] connection error',
  'connection_lost':   '[ERROR] connection lost',
  'connect_timeout':   '[ERROR] connection timed out',
};

String describeConnectionError(String? code) =>
    kConnectionErrorMessages[code] ?? '[ERROR] connection failed';
```

Conventions:
- All strings use the existing `[ERROR] …` lowercased pattern from JoinRoomScreen.
- `describeConnectionError(null)` returns the generic fallback.
- Do not import `flutter` here — keep it pure Dart.

### Part D — JoinRoomScreen: use the shared mapping

In [lib/screens/join_room_screen.dart](../lib/screens/join_room_screen.dart):

1. Delete the inline `_errorMessages` map and `_mapError` method.
2. Import `../network/error_messages.dart`.
3. Replace the call site with `_error = describeConnectionError(client.lastError);`.
4. No other behavior change in this screen — it already shows error text and re-enables the button on retry. Confirm the test for join still passes.

### Part E — RoomSetupScreen: surface error + retry on `Generate Code` failure

In [lib/screens/room_setup_screen.dart](../lib/screens/room_setup_screen.dart):

1. Add a `String? _error;` field on `_RoomSetupScreenState`.
2. In `_generateCode`, set `_error = null` at the top alongside `_generating = true`.
3. In `_onClientChanged`, replace the `error && _generating` branch with:
   ```dart
   } else if (client.state == ChatConnectionState.error && _generating) {
     _generating = false;
     setState(() {
       _error = describeConnectionError(client.lastError);
     });
   }
   ```
4. Render the error inline above the CTA button, mirroring JoinRoomScreen's pattern (warning-tone mono text, small bottom margin). Use the existing `palette.warning` color slot — no new tokens.
5. The CTA button stays — its label remains `Generate Code` (not `Retry`) on a fresh attempt; tapping it again calls `_generateCode` which already runs `chatClient.close()`-equivalent semantics... **wait, it does not** — the current `_generateCode` does not call `close()` first. Add `await widget.chatClient.close();` before the `addListener` call in `_generateCode` **only when `_error != null`** (i.e. retrying after a failure). On first attempt, `chatClient` is fresh and `close()` is a no-op but unnecessary; calling it is still safe (idempotent per Task 11). Pragmatically: just always call it at the top of `_generateCode`. Simpler and provably correct.

   Actually re-examining: the current state machine sets `_state = error` on failure, but `_channel` may still be non-null if the failure was a timeout (we close it, but in the connection_failed catch we currently leave `_channel = null` because we never assigned). The cleanest invariant is: `_generateCode` always starts by calling `chatClient.close()` to guarantee a clean slate, then proceeds. Implement that.

### Part F — RoomSetupScreen: drop UX after code generated

When `_codeGenerated == true` and the connection drops (state transitions to `closed` or `error`) while waiting for a peer:

1. Add a transition handler in `_onClientChanged`:
   ```dart
   else if (_codeGenerated &&
            (client.state == ChatConnectionState.closed ||
             client.state == ChatConnectionState.error)) {
     // Connection died before peer joined.
     setState(() {
       _error = describeConnectionError(client.lastError ?? 'connection_lost');
     });
   }
   ```
2. When `_error != null` after code generation: replace the `WAITING FOR PEER` micro-text in the top bar with `CONNECTION LOST`, color `palette.warning`. Replace the bottom CTA spacer with a `Retry` button that runs:
   ```dart
   await widget.chatClient.close();
   setState(() {
     _codeGenerated = false;
     _error = null;
   });
   // user is back to the pre-generation state with their nickname + password-mode toggle preserved
   ```
   The retry resets the screen to its initial step — the *room code* itself is gone (it was server-side state, now destroyed). The user taps `Generate Code` again to get a fresh code.

   This is intentional UX: you don't get to keep the same code through a reconnect, because the server side has freed it.
3. Do **not** auto-trigger `Generate Code` after the close. The user has to opt in by tapping.

### Part G — Verify ChatScreen post-pairing drop behavior

Read-only check, no expected changes:

- `_onClientChanged` in [chat_screen.dart](../lib/screens/chat_screen.dart) flips `_peerLeft = true` on `state == closed`.
- `peer_left` and `connection_lost` both arrive as `state == closed` (the former via `PeerLeftMsg` → `_setState(closed)`; the latter via `_onDone` → `_setState(closed)` with `lastError = 'connection_lost'`).
- The chat screen does not currently distinguish *peer left* from *we lost the connection*. That's fine for this task — both terminate the room. If you observe the system message `peer disconnected — room closed` is misleading when *we* dropped, leave it for a later UX-polish task and note it in result.md.

### Part H — Tests

In [test/network/chat_client_test.dart](../test/network/chat_client_test.dart), add a group `connect timeout`:

- Mock `WebSocketChannel.connect` to return a channel whose `ready` future never completes (or completes after a controllable duration). Difficult without a fake — if the existing test scaffolding doesn't already support a fake channel, **skip the timeout integration test** and instead unit-test the constant: assert `_connectTimeout` is `Duration(seconds: 8)` via a `@visibleForTesting` getter or a public `static const`. Document in result.md that the timeout is asserted by configuration, not by integration.
- Idempotent retry: call `joinRoom('FAKE-0000')` against a server that returns `not_found`, then call again. Assert state cleanly resets each attempt and `chatClient.lastError` reflects only the latest call.

In [test/network/error_messages_test.dart](../test/network/error_messages_test.dart) (new file):

- Each known code maps to a non-empty `[ERROR] …` string.
- Unknown code returns the generic fallback.
- `null` returns the generic fallback.

In [test/screens/](../test/screens/), if a `room_setup_screen_test.dart` exists, add cases:

- On `state == error`, the screen renders the mapped error string and the CTA returns to `Generate Code`.
- After code-generated state, on a subsequent `state == closed`, `CONNECTION LOST` is shown and the `Retry` button is present.

If the test directory does not yet have a `room_setup_screen_test.dart`, create one — same scaffolding as the chat_screen widget test from Task 10.

### Part I — `flutter analyze`, `flutter test`, `npm test`

All clean. Flutter test count grows from 75. Server tests stay at 43.

### Part J — Commit

One commit:

`feat: connect-error ux — timeout, mapped errors, retry on room setup`

### Part K — Output (in your response and at the top of `result.md`)

- Confirm `flutter analyze` clean.
- `flutter test` count vs. Task 12's 75.
- `npm test` count (expect unchanged: 43).
- `git diff --name-only main..HEAD` — expect: `chat_client.dart`, new `error_messages.dart`, `join_room_screen.dart`, `room_setup_screen.dart`, new `error_messages_test.dart`, possibly `room_setup_screen_test.dart`, plus `result.md` / `sessions.md` / `changelog.md`.
- One sentence on whether the post-pairing-drop message in ChatScreen (`peer disconnected — room closed`) feels misleading when *we* dropped, and whether that warrants a tiny copy fix in this task or a separate one.

### Part L — Update docs/result.md, docs/sessions.md, docs/changelog.md

Per CLAUDE.md §4–§6.

In sessions.md, tick:
- [x] Connection error handling + retry UX

Leave the rest of Phase 3 unchecked.

## Specs

- Branch: `task/connect-error-ux` (off `main`, after merging Task 12).
- One commit at the end.
- No new dependencies.
- No protocol changes.
- No new components or tokens.
- No auto-reconnect — manual retry only.

## Do NOT

- Do not add exponential backoff or auto-reconnect.
- Do not change the chat screen's post-pairing drop behavior.
- Do not add a "preserve room code through reconnect" feature — the room code is server-side state and dies with the connection.
- Do not log connection failures (no new `debugPrint` calls outside `kDebugMode`-gated lifecycle messages already in place).
- Do not extend `ChatConnectionState` with new values. The five existing values plus `_lastError` are sufficient.
- Do not push the branch.

## Commit Message

`feat: connect-error ux — timeout, mapped errors, retry on room setup`
