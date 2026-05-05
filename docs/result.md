# Last Task Result

## Task
Lifecycle hardening — shutdown contract, drop deprecated removeRoom, Phase 1 closeout (Phase 1, Task 6).

## Branch
task/server-lifecycle-hardening

## Commit
chore: lifecycle hardening — shutdown contract, drop deprecated removeRoom

## What Was Done

### File tree (modified/deleted) under `server/`
```
server/src/
  server.js       (MODIFIED — shutdown contract comment, teardown() called in close())
  ws.js           (MODIFIED — attachWebSocket returns { wss, teardown })
  rooms.js        (MODIFIED — removed deprecated removeRoom(code))
  index.js        (MODIFIED — 5-second hard timeout on SIGINT/SIGTERM)
server/test/
  smoke.test.js   (MODIFIED — 29 tests: 27 prior + 2 lifecycle)
server/README.md  (MODIFIED — Lifecycle section, status bump to Phase 1 closed)
```

### Shutdown contract comment
`server/src/server.js:1-9`:
```
// Shutdown contract. When close() is awaited:
// 1. The HTTP/HTTPS server stops accepting new connections.
// 2. The WebSocketServer stops accepting new upgrades.
// 3. The heartbeat interval is cleared.
// 4. All open client sockets are terminated (forcefully — we do not wait
//    for graceful WebSocket close handshakes during shutdown).
// 5. The returned promise resolves once steps 1–4 are complete.
// 6. Process holds no active timers, no open sockets. SIGINT/SIGTERM in
//    index.js triggers close() and then process.exit(0).
```

### removeRoom deletion
`git grep removeRoom` — zero references remain. Function and export deleted from rooms.js.

### npm test — 29/29 pass
```
  GET /health returns 200 with version string
  GET /nope returns 404
  WS connects on /ws and receives hello frame
  WS wrong path is rejected
  create_room returns a well-formed code
  second create_room on same socket -> already_in_room
  bad JSON -> bad_message
  unknown type -> unknown_type
  oversized frame -> bad_message
  disconnect removes the room
  successful join — joiner gets joined, creator gets peer_joined
  wrong code -> not_found
  code with bad format -> bad_message
  room full — third client rejected
  cannot join own room
  joiner already in another room -> already_in_room
  joiner disconnects -> creator gets peer_left, room removed
  creator disconnects -> joiner gets peer_left, room removed
  Relay: A -> B relay
  Relay: B -> A relay
  Relay: sender not in a room -> not_in_room
  Relay: sender unpaired -> not_paired
  Relay: missing payload -> bad_message
  Relay: non-string payload -> bad_message
  Relay: oversized frame -> bad_message, peer receives nothing
  Relay: server does not modify payload (special chars)
  Lifecycle: shutdown completes within 500ms with 5 connected clients
  Lifecycle: heartbeat interval is cleared on shutdown
  server closes cleanly with open ws client
tests 29 | pass 29 | fail 0
```

### Shutdown elapsed time
~6ms with 5 connected clients (well under 500ms limit).

### Flutter verification
- `flutter analyze` — No issues found
- `flutter test` — All tests passed (4/4)

## Status
Done

## Notes
- `attachWebSocket` now returns `{ wss, teardown }` instead of bare `wss`. The `teardown()` function is called explicitly in `close()` before `server.close()`, ensuring WS clients are terminated and the heartbeat interval cleared before the HTTP server close is awaited. The `httpServer.on('close')` handler remains as a safety net.
- The 5-second hard timeout in index.js uses `.unref()` so it doesn't itself prevent process exit.
- Phase 1 is now fully closed. All 6 checklist items marked done.
