# Last Task Result

## Task
WebSocket endpoint with optional TLS and hello frame (Phase 1, Task 2).

## Branch
task/server-websocket-tls

## Commit
feat: websocket endpoint with optional TLS and hello frame

## What Was Done

### File tree — created or modified under `server/`
```
server/
  package.json              (MODIFIED — added ws@^8 dependency)
  package-lock.json         (MODIFIED — ws added)
  .gitignore                (MODIFIED — added *.pem)
  README.md                 (MODIFIED — updated run/status sections)
  src/
    index.js                (MODIFIED — slim entry, delegates to server.js)
    config.js               (MODIFIED — frozen object, TLS + WS_PATH env vars)
    log.js                  (unchanged)
    server.js               (NEW — http/https factory, start() export)
    ws.js                   (NEW — WebSocket attach, hello frame, heartbeat)
  test/
    smoke.test.js           (MODIFIED — 5 tests: 2 HTTP + 3 WebSocket)
```

### Startup log line (HTTP mode)
```
[2026-05-05T12:27:54.437Z] [info] server listening on http://127.0.0.1:3000 (ws path: /ws)
```

### HTTPS variant (from source, server.js:36)
```
server listening on https://${host}:${actualPort} (ws path: ${wsPath})
```

### npm test output
```
▶ HTTP
  ✔ GET /health returns 200 with version string (11ms)
  ✔ GET /nope returns 404 (1ms)
✔ HTTP (13ms)
▶ WebSocket
  ✔ connects on /ws and receives hello frame (4ms)
  ✔ wrong path is rejected (2ms)
  ✔ server closes cleanly with open ws client (2ms)
✔ WebSocket (8ms)
tests 5 | pass 5 | fail 0
```

### No-client-data comment confirmation
`server/src/ws.js:1-6` carries the hard rule:
```
// HARD RULE: This module MUST NEVER log request bodies, IP addresses, headers,
// room codes, frame contents, or anything derived from a client connection.
// No console.log(message). No logging of request.headers,
// request.socket.remoteAddress, or frame contents. Lifecycle counts only
// (startup, shutdown). This rule is the foundation of the "we cannot read your
// messages and we don't know who you are" promise.
```

### *.pem gitignored
`server/.gitignore` line 6: `*.pem`

### Flutter verification
- `flutter analyze` — No issues found
- `flutter test` — All tests passed (4/4)

## Status
Done

## Notes
- `ws` is the only runtime dependency (no transitives).
- TLS is opt-in via `TLS_CERT_PATH` + `TLS_KEY_PATH`. Half-configured throws on startup.
- WebSocket path configurable via `WS_PATH` (default `/ws`).
- Server tracks connections for forceful shutdown (needed for clean test teardown).
- No TLS test in the suite — documented in README as manual-only for now.
