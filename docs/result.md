# Last Task Result

## Task
1:1 room join with peer pairing and disconnect notifications (Phase 1, Task 4).

## Branch
task/server-room-join

## Commit
feat: 1:1 room join with peer pairing and disconnect notifications

## What Was Done

### File tree — modified under `server/`
```
server/src/
  protocol.js     (MODIFIED — added join_room, joined, peer_joined, peer_left, CODE_REGEX)
  rooms.js        (MODIFIED — added joinRoom, leaveRoom; room state now has joiner/pairedAt)
  ws.js           (MODIFIED — join_room handler, leaveRoom on close, peer_left notification)
server/test/
  smoke.test.js   (MODIFIED — 19 tests total: 11 prior + 8 pairing)
server/README.md  (MODIFIED — 8 message types, pairing note, status bump)
```

### Updated wire-protocol table (all 8 types)
| Type | Direction | Shape |
|------|-----------|-------|
| `hello` | server → client | `{type:"hello", v:"0.1.0"}` |
| `create_room` | client → server | `{type:"create_room"}` |
| `room_created` | server → client | `{type:"room_created", code:"WORD-NNNN"}` |
| `join_room` | client → server | `{type:"join_room", code:"WORD-NNNN"}` |
| `joined` | server → joiner | `{type:"joined", code:"WORD-NNNN"}` |
| `peer_joined` | server → creator | `{type:"peer_joined"}` |
| `peer_left` | server → survivor | `{type:"peer_left"}` |
| `error` | server → client | `{type:"error", code:"<slug>", reason:"<fixed>"}` |

### npm test — 19/19 pass
```
✔ GET /health returns 200 with version string
✔ GET /nope returns 404
✔ WS connects on /ws and receives hello frame
✔ WS wrong path is rejected
✔ create_room returns a well-formed code
✔ second create_room on same socket → already_in_room
✔ bad JSON → bad_message
✔ unknown type → unknown_type
✔ oversized frame → bad_message
✔ disconnect removes the room
✔ successful join — joiner gets joined, creator gets peer_joined
✔ wrong code → not_found
✔ code with bad format → bad_message
✔ room full — third client rejected
✔ cannot join own room
✔ joiner already in another room → already_in_room
✔ joiner disconnects → creator gets peer_left, room removed
✔ creator disconnects → joiner gets peer_left, room removed
✔ server closes cleanly with open ws client
tests 19 | pass 19 | fail 0
```

### rooms.js has no ws.send calls
Grep for `ws.send` in rooms.js: 0 matches. All I/O stays in ws.js.

### ws.js still carries the no-client-data comment
`server/src/ws.js:1-6` — hard rule intact. No message-path logging added.

### Flutter verification
- `flutter analyze` — No issues found
- `flutter test` — All tests passed (4/4)

## Status
Done

## Notes
- `joinRoom` checks `cannot_join_own` before `already_in_room` so the creator gets the more specific error.
- Room shape: `{ creator, joiner, createdAt, pairedAt }`. Either party leaving destroys the room entirely.
- `leaveRoom(ws)` returns `{ removed, notify }` — ws.js does the sending.
- Old `removeRoom(code)` kept but marked deprecated.
