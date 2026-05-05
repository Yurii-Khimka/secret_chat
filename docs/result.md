# Last Task Result

## Task
Real-time encrypted-payload relay — server forwards `msg` frames between paired peers without inspecting, logging, or storing payloads (Phase 1, Task 5).

## Branch
task/server-relay

## Commit
feat: opaque-payload message relay between paired peers

## What Was Done

### File tree (modified) under `server/`
```
server/src/
  protocol.js     (MODIFIED — added MSG_MSG, raised MAX_FRAME_SIZE to 16 KB)
  rooms.js        (MODIFIED — added getPeer(ws))
  ws.js           (MODIFIED — MSG_MSG relay handler, silent path)
server/test/
  smoke.test.js   (MODIFIED — 27 tests total: 19 prior + 8 relay)
server/README.md  (MODIFIED — 9 message types, relay invariants, status bump)
```

### Updated wire-protocol table (all 9 types)
| Type | Direction | Shape |
|------|-----------|-------|
| `hello` | server -> client | `{type:"hello", v:"0.1.0"}` |
| `create_room` | client -> server | `{type:"create_room"}` |
| `room_created` | server -> client | `{type:"room_created", code:"WORD-NNNN"}` |
| `join_room` | client -> server | `{type:"join_room", code:"WORD-NNNN"}` |
| `joined` | server -> joiner | `{type:"joined", code:"WORD-NNNN"}` |
| `peer_joined` | server -> creator | `{type:"peer_joined"}` |
| `peer_left` | server -> survivor | `{type:"peer_left"}` |
| `msg` | bidirectional | `{type:"msg", payload:"<opaque string>"}` |
| `error` | server -> client | `{type:"error", code:"<slug>", reason:"<fixed string>"}` |

### Silent-path comment
`server/src/ws.js:83` — `// RELAY: silent path. Do not add logging here.`

### npm test — 27/27 pass
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
  server closes cleanly with open ws client
tests 27 | pass 27 | fail 0
```

### Relay path logging verification
grep for `console.` / `log.info(` / `log.warn(` in ws.js relay branch: **0 matches**.

### Flutter verification
- `flutter analyze` — No issues found
- `flutter test` — All tests passed (4/4)

## Status
Done

## Notes
- `getPeer(ws)` returns null for both unpaired and not-in-room cases; the relay handler differentiates by checking `ws.roomCode` first.
- Relay try/catch on peer.send swallows errors silently — dead peers are detected via the existing `peer_left` mechanism.
- Frame cap raised to 16 KB to accommodate future AES-256-GCM ciphertext + base64. The cap bounds parse work, not payload inspection.
