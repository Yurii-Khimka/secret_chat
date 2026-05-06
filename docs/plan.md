# Plan

_Updated by the Tech Lead chat before each task._

## Status

**Active task:** Phase 2 / Task 12 — **Zero server-side logging audit**.

Project rule from [docs/readme.md](readme.md):

> No IP address logging. No data stored on the server.

The server has been written from day one with a "no client data" rule (see hard-rule comment at the top of [server/src/ws.js](../server/src/ws.js)). Task 12 makes that rule **enforced by tests** rather than enforced by discipline. The audit also locks the contract in writing.

## Context

### Current logging surface

A quick survey of [server/src/](../server/src/) shows the logging surface is already minimal:

```
log.js:    info() → process.stdout.write    (lifecycle)
log.js:    warn() → process.stderr.write    (lifecycle)
server.js: info('server listening on …')    (startup)
index.js:  info('shutting down')            (SIGINT/SIGTERM)
index.js:  warn('shutdown timed out …')     (fatal timeout)
```

Three call sites total. None of them are on the data path. Task 12's job is to:

1. **Verify** the data path stays silent under realistic traffic (create → join → relay → bad frames → disconnect).
2. **Verify** no IP / header / URL-query / frame-content capture exists anywhere in the codebase, even outside the logger (e.g. accidental `req.socket.remoteAddress` reads, header reflection in errors).
3. **Lock** the allowed-log-line set so future PRs can't quietly add a `console.log(payload)`.
4. **Document** the contract in one canonical place.

### What "data path" means precisely

Any code reachable from a WebSocket message arriving at the server. Specifically:

- `ws.js`'s `connection` handler (frame parsing, dispatch, error replies).
- `protocol.js` (`parseMessage`, `errorMessage`).
- `rooms.js` (`createRoom`, `joinRoom`, `leaveRoom`, `getPeer`, `removeRoom`).
- `wordlist.js` (room-code generation).

The only allowed log calls are **lifecycle**:
- Server startup (one line, includes host/port/ws-path — none are client-derived).
- Server shutdown (one line, no client data).
- Shutdown timeout (one line, no client data).
- Fatal errors that cause the process to exit (uncaught exceptions, configuration failures at boot).

Anything else — including a debug log of "room created with code X" — is **forbidden**, because room codes are still ephemeral session identifiers; the codebase already trusts this rule and we're locking it in.

### What we are NOT doing

- Not adding a logging framework (winston, pino, etc.). The current `log.js` is fine.
- Not adding log levels beyond `info`/`warn`. No `debug`.
- Not adding a "redact this field" helper — the contract is "don't log it at all," not "log a scrubbed version."
- Not changing what the server returns to clients (error frames stay as-is).
- Not changing the Flutter side of the project. Client-side logging audit is a separate task if needed.

## Read First

- [CLAUDE.md](../CLAUDE.md)
- [docs/result.md](result.md) — Task 11 closeout
- [docs/sessions.md](sessions.md) — Phase 2 locked constraints
- [docs/readme.md](readme.md) — "No IP address logging"
- [docs/changelog.md](changelog.md)
- [server/src/log.js](../server/src/log.js)
- [server/src/ws.js](../server/src/ws.js) — top-of-file hard rule comment
- [server/src/server.js](../server/src/server.js)
- [server/src/index.js](../server/src/index.js)
- [server/src/protocol.js](../server/src/protocol.js)
- [server/src/rooms.js](../server/src/rooms.js)
- [server/test/smoke.test.js](../server/test/smoke.test.js) — existing test patterns
- [server/README.md](../server/README.md) — where the contract gets documented

## Current Task

### Part A — Branching

1. Switch to `main`. Merge `task/security-cleanup` into `main` (no fast-forward).
2. Delete the local `task/security-cleanup` branch.
3. Branch off `main` as `task/server-logging-audit`.

### Part B — Static audit (read-only first pass)

Walk every file under `server/src/` and classify each potentially-logging or potentially-PII operation. **Produce no code changes in this part** — the goal is to confirm the surface before writing tests.

For each, record (in your scratch notes, will go into result.md):

1. **Logging primitives**: every `console.*`, `process.stdout.*`, `process.stderr.*`, every call to `info`/`warn`/`error` exported from `log.js`. Expected hits: 3 call sites + the 2 inside `log.js`.
2. **PII / network-identifier reads**: every reference to `req.socket.remoteAddress`, `req.connection.remoteAddress`, `req.headers`, `req.url` (beyond the WS upgrade path check), `x-forwarded-for`, `x-real-ip`. Expected hits: 0.
3. **Frame-content reflection**: every place where data from a parsed message (`text`, `ciphertext`, `nonce`, `code`, `nickname`, etc.) is interpolated into an error reply, log line, or stack trace. Expected: error frames carry only fixed `code` + fixed `reason` strings — zero echoing of client input. Confirm.
4. **Stack traces**: any `error.stack` that could land in `process.stderr` and reveal client input via interpolation. Expected: none reach the data path.

If any item in 2/3/4 is found, **fix it in this task** (it's the audit; the audit fixing what it finds is in scope).

### Part C — Logging contract test (the load-bearing piece)

New file: [server/test/logging.test.js](../server/test/logging.test.js).

Purpose: drive a realistic session through the real server stack and prove zero data-path logs are emitted. Lifecycle logs (startup, shutdown) are explicitly allowed and asserted by name.

Structure:

```js
import { test } from 'node:test';
import assert from 'node:assert';
import { startServer, stopServer } from '../src/server.js'; // or whatever the real entrypoint exposes

// Capture every byte that hits stdout/stderr during the test.
function captureStdio(fn) {
  const stdout = [];
  const stderr = [];
  const origOut = process.stdout.write.bind(process.stdout);
  const origErr = process.stderr.write.bind(process.stderr);
  process.stdout.write = (chunk) => { stdout.push(chunk.toString()); return true; };
  process.stderr.write = (chunk) => { stderr.push(chunk.toString()); return true; };
  try { return { stdout, stderr, result: fn() }; }
  finally { process.stdout.write = origOut; process.stderr.write = origErr; }
}
```

Tests:

1. **Lifecycle-only baseline**: start server → assert stdout contains exactly one line matching `/server listening on/`, stderr empty. Stop server → assert one additional `/shutting down/` line, stderr still empty.

2. **Data-path silence**: start server, open two WS clients, run a full session:
   - Client A sends `create_room`.
   - Client B sends `join_room`.
   - A and B exchange 3 plaintext `msg` frames each.
   - Open a *new* room with `password_mode: true` and exchange 3 ciphertext `msg` frames each.
   - A sends 3 *malformed* frames: oversized (4097-char text), bad shape (both text and ciphertext), unknown type.
   - Disconnect A (close), then B observes `peer_left`.
   - Stop server.

   Capture stdout+stderr across the whole session. **Assert**: exactly the 2 lifecycle lines (`server listening`, `shutting down`). No additional lines. No occurrence of any of the strings sent by clients (room codes, nicknames, ciphertexts, nonces, plaintexts) in either stream.

3. **Error frames don't leak inputs**: send a `join_room` with code `WOLF-9999` (nonexistent). Capture the error reply and the stdio. Assert: stdio contains zero occurrences of `WOLF-9999`. Error reply's `reason` is the fixed string for that error code (never the client's input).

4. **No remoteAddress access**: this is a static check, not a runtime one. Use `fs.readFileSync` to read each file in `server/src/` and assert none contain the strings `remoteAddress`, `x-forwarded-for`, `x-real-ip`. (The current `ws.js` comment mentions `remoteAddress` to forbid it — exempt comment lines: strip lines starting with `//` or inside `/* */` before the assertion. Implementation: a tiny regex pass is fine.)

   The exemption needs care — match the *forbidden access* pattern, not the literal word. A pragmatic rule: assert no source file contains `.remoteAddress` (with the leading dot) outside comments. That catches `req.socket.remoteAddress` and `req.connection.remoteAddress` while letting the existing forbidding-comment in `ws.js` pass.

### Part D — Document the contract

Add a section to [server/README.md](../server/README.md) titled `## Logging contract`. Write it concisely (≤ 15 lines). Content:

- The only log lines this server emits are: server startup (one line), server shutdown (one line), shutdown timeout warning (one line).
- The server logs zero client-derived data: no IP addresses, no headers, no URL params, no frame contents, no room codes, no nicknames, no error reasons that echo client input.
- This contract is enforced by [server/test/logging.test.js](../server/test/logging.test.js). New `console.*` / `info()` / `warn()` calls on the data path will fail that test.
- If lifecycle lines need to change (e.g. process supervisor wants a different format), update the test's expected line set in the same commit.

### Part E — Reinforce ws.js header comment

The hard-rule comment at the top of [server/src/ws.js](../server/src/ws.js) is good. Add one line pointing to the test file:

```
// Enforced by server/test/logging.test.js — that test will fail if a console.log
// or info() call lands on the data path.
```

No other changes to `ws.js`.

### Part F — `npm test`, `flutter test`, `flutter analyze`

- `npm test`: count grows from 39 (expect ~43 — 4 new logging tests).
- `flutter test`: unchanged at 75.
- `flutter analyze`: clean (untouched, but run anyway).

### Part G — Commit

One commit:

`chore: server logging audit — lock zero-data-path-log contract`

### Part H — Output (in your response and at the top of `result.md`)

- The **static audit findings table**: each file in `server/src/`, each logging/PII access (with line number), classification (allowed lifecycle / forbidden / not-present). This is the primary evidence the audit was actually performed.
- Confirm `npm test` count vs. Task 11's 39.
- Confirm `flutter test` unchanged at 75, `flutter analyze` clean.
- `git diff --name-only main..HEAD` — expect: `ws.js` (one comment line), `server/README.md` (new section), `server/test/logging.test.js` (new file). And `result.md`/`sessions.md`/`changelog.md` per CLAUDE.md.
- Note: if the audit found and fixed any actual leak, call it out clearly. (If it found none, say so explicitly — that's the expected outcome and worth confirming.)

### Part I — Update docs/result.md, docs/sessions.md, docs/changelog.md

Per CLAUDE.md §4–§6.

In sessions.md, tick:
- [x] Verify zero server-side logging (no IPs, no payloads, no metadata beyond room code)

That closes the last actionable Phase 2 item (key-verification handshake is already marked superseded). Note in sessions.md that **Phase 2 — Security is now complete**.

## Specs

- Branch: `task/server-logging-audit` (off `main`, after merging Task 11).
- One commit at the end.
- No new dependencies (Node built-in test runner only).
- No new server code paths; only a comment line in `ws.js`, a README section, and a test file.
- No client-side changes.

## Do NOT

- Do not add a logging framework or new log levels.
- Do not add a "scrub" / "redact" helper. The rule is don't-log, not log-then-scrub.
- Do not change error frame shapes or codes.
- Do not log room codes "for debugging" anywhere — the contract treats them as session-ephemeral.
- Do not silence any *existing* lifecycle line (startup/shutdown). The audit confirms them; it doesn't remove them.
- Do not push the branch.

## Commit Message

`chore: server logging audit — lock zero-data-path-log contract`
