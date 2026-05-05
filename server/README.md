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

## Logging policy

The logger MUST NEVER log request bodies, IP addresses, headers, room codes, or anything derived from a client connection. It is for server-lifecycle events only (startup, shutdown, internal errors). This rule is the foundation of the "we cannot read your messages and we don't know who you are" promise.

## TLS testing

TLS is not exercised by `npm test` yet — generating a self-signed cert in CI adds complexity for marginal value at this stage. Manual verification only for now. Re-evaluate when we have a deployment target.

## Status

WebSocket endpoint live at `WS_PATH` (default `/ws`). Sends a `hello` frame on connect. No room logic, no relay, no encryption yet — next tasks.
