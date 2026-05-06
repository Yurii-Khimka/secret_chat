# secret-chat-server

## Purpose

Relay server for secret_chat. Sees room codes only; cannot read messages.

## Run

**Plain (dev):**

```bash
npm install
npm run dev
# HTTP: curl localhost:3000/health
# WS:   ws://localhost:3000/ws
```

**With TLS:**

```bash
# Generate a self-signed cert for local testing:
openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 30 -subj "/CN=localhost"

TLS_CERT_PATH=./cert.pem TLS_KEY_PATH=./key.pem npm start
# wss://localhost:3000/ws
```

## Test

```bash
npm test
```

The test imports `start({ port: 0 })` from `src/server.js` to bind on a random port. Running `node src/index.js` directly still works as the normal entry point.

## Wire protocol

v0.1 — will grow.

| Type | Direction | Shape |
|------|-----------|-------|
| `hello` | server → client | `{type:"hello", v:"0.1.0"}` |
| `create_room` | client → server | `{type:"create_room"}` |
| `room_created` | server → client | `{type:"room_created", code:"WORD-NNNN"}` |
| `join_room` | client → server | `{type:"join_room", code:"WORD-NNNN"}` |
| `joined` | server → joiner | `{type:"joined", code:"WORD-NNNN"}` |
| `peer_joined` | server → creator | `{type:"peer_joined"}` |
| `peer_left` | server → survivor | `{type:"peer_left"}` |
| `msg` | bidirectional | `{type:"msg", payload:"<opaque string>"}` |
| `error` | server → client | `{type:"error", code:"<slug>", reason:"<fixed string>"}` |

Pairing is 1:1. Either party leaving destroys the room.

Frame cap: 16 KB per message.

### Relay invariants

- Server forwards `payload` verbatim. No decode, no transform, no inspection.
- Server does not log `msg` frames in any form.
- Server stores nothing about the conversation beyond the ws-to-room binding.

## Logging contract

The only log lines this server emits are:
- **Startup**: one line (`server listening on …`) — contains host/port/ws-path, none client-derived.
- **Shutdown**: one line (`shutting down`) — no client data.
- **Shutdown timeout**: one line (`shutdown timed out …`) — no client data.

The server logs **zero** client-derived data: no IP addresses, no headers, no URL params, no frame contents, no room codes, no nicknames, no error reasons that echo client input.

This contract is enforced by `server/test/logging.test.js`. Any new `console.*` / `info()` / `warn()` call on the data path will fail that test. If lifecycle lines need to change, update the test's expected line set in the same commit.

## Lifecycle

Shutdown contract. When `close()` is awaited:

1. The HTTP/HTTPS server stops accepting new connections.
2. The WebSocketServer stops accepting new upgrades.
3. The heartbeat interval is cleared.
4. All open client sockets are terminated (forcefully — we do not wait for graceful WebSocket close handshakes during shutdown).
5. The returned promise resolves once steps 1–4 are complete.
6. Process holds no active timers, no open sockets. SIGINT/SIGTERM in `index.js` triggers `close()` and then `process.exit(0)`.

SIGINT/SIGTERM have a 5-second hard cap — if `close()` doesn't resolve in time, the process exits with code 1.

## TLS testing

TLS is not exercised by `npm test` yet — generating a self-signed cert in CI adds complexity for marginal value at this stage. Manual verification only for now. Re-evaluate when we have a deployment target.

## Status

Connections + room creation + 1:1 pairing + opaque relay + clean shutdown. Phase 1 closed. Next: Phase 2 — on-device Argon2 + AES-256.
