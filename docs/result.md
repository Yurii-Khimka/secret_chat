# Last Task Result

## Task
Room creation with in-memory registry and wire protocol v0.1 (Phase 1, Task 3).

## Branch
task/server-room-creation

## Commit
feat: room creation with in-memory registry and wire protocol v0.1

## What Was Done

### File tree — new/modified under `server/`
```
server/
  src/
    protocol.js           (NEW — message constants, parseMessage, errorMessage)
    wordlist.js           (NEW — 64 frozen uppercase nouns)
    rooms.js              (NEW — in-memory Map registry, createRoom/removeRoom)
    ws.js                 (MODIFIED — message handler, room lifecycle)
  test/
    smoke.test.js         (MODIFIED — 11 tests total)
  README.md               (MODIFIED — wire protocol section, status bump)
```

### Wire protocol (4 message types)
| Type | Direction | Shape |
|------|-----------|-------|
| `hello` | server → client | `{type:"hello", v:"0.1.0"}` |
| `create_room` | client → server | `{type:"create_room"}` |
| `room_created` | server → client | `{type:"room_created", code:"WORD-NNNN"}` |
| `error` | server → client | `{type:"error", code:"<slug>", reason:"<fixed string>"}` |

### First 8 words from wordlist
WOLF, FERN, MOON, IRON, OAK, JADE, ASH, RAIN

### npm test output
```
▶ secret-chat-server
  ✔ GET /health returns 200 with version string (5ms)
  ✔ GET /nope returns 404 (1ms)
  ✔ WS connects on /ws and receives hello frame (5ms)
  ✔ WS wrong path is rejected (1ms)
  ✔ create_room returns a well-formed code (2ms)
  ✔ second create_room on same socket → already_in_room (2ms)
  ✔ bad JSON → bad_message (1ms)
  ✔ unknown type → unknown_type (1ms)
  ✔ oversized frame → bad_message (1ms)
  ✔ disconnect removes the room (52ms)
  ✔ server closes cleanly with open ws client (2ms)
✔ secret-chat-server (80ms)
tests 11 | pass 11 | fail 0
```

### No-client-data rule
`server/src/ws.js:1-6` still carries the hard rule comment. No log lines added on the message path.

### ws.roomCode decision
`ws.roomCode` is attached directly to the WebSocket instance (documented in `rooms.js:3`) because the WS lifecycle already drives cleanup — avoids a parallel Map to keep in sync.

### Flutter verification
- `flutter analyze` — No issues found
- `flutter test` — All tests passed (4/4)

## Status
Done

## Notes
- 64-word list × 10000 numbers = 640,000 code namespace; collision retry up to 10 attempts.
- Frame size capped at 1 KB for room-phase messages.
- Error frames never echo client content — only fixed server strings.
- No new dependencies (still just `ws`).
