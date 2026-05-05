# secret-chat-server

## Purpose

Relay server for secret_chat. Sees room codes only; cannot read messages.

## Run

```bash
npm install
npm run dev
curl localhost:3000/health
```

## Test

```bash
npm test
```

The test imports and calls `start(0)` from `src/index.js` to bind on a random port — no subprocess needed. Running `node src/index.js` directly still works as the normal entry point.

## Logging policy

The logger MUST NEVER log request bodies, IP addresses, headers, room codes, or anything derived from a client connection. It is for server-lifecycle events only (startup, shutdown, internal errors). This rule is the foundation of the "we cannot read your messages and we don't know who you are" promise.

## Status

Skeleton only. No WebSocket, no rooms, no TLS yet — next tasks.
