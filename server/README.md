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

## Logging policy

The logger MUST NEVER log request bodies, IP addresses, headers, room codes, or anything derived from a client connection. It is for server-lifecycle events only (startup, shutdown, internal errors). This rule is the foundation of the "we cannot read your messages and we don't know who you are" promise.

## TLS testing

TLS is not exercised by `npm test` yet — generating a self-signed cert in CI adds complexity for marginal value at this stage. Manual verification only for now. Re-evaluate when we have a deployment target.

## Status

Connections + room creation + 1:1 pairing + opaque-payload relay. No encryption yet — payload is whatever the client sends.
