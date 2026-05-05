// HARD RULE: This module MUST NEVER log request bodies, IP addresses, headers,
// room codes, frame contents, or anything derived from a client connection.
// No console.log(message). No logging of request.headers,
// request.socket.remoteAddress, or frame contents. Lifecycle counts only
// (startup, shutdown). This rule is the foundation of the "we cannot read your
// messages and we don't know who you are" promise.

import { WebSocketServer } from 'ws';
import config from './config.js';

const HEARTBEAT_INTERVAL = 30_000;

export function attachWebSocket(httpServer) {
  const wss = new WebSocketServer({ noServer: true });
  let heartbeatTimer;

  httpServer.on('upgrade', (request, socket, head) => {
    const { pathname } = new URL(request.url, `http://${request.headers.host}`);

    if (pathname === config.wsPath) {
      wss.handleUpgrade(request, socket, head, (ws) => {
        wss.emit('connection', ws, request);
      });
    } else {
      socket.write('HTTP/1.1 404 Not Found\r\n\r\n');
      socket.destroy();
    }
  });

  wss.on('connection', (ws) => {
    ws.isAlive = true;
    ws.on('pong', () => { ws.isAlive = true; });
    ws.send(JSON.stringify({ type: 'hello', v: '0.1.0' }));
  });

  heartbeatTimer = setInterval(() => {
    for (const ws of wss.clients) {
      if (!ws.isAlive) {
        ws.terminate();
        continue;
      }
      ws.isAlive = false;
      ws.ping();
    }
  }, HEARTBEAT_INTERVAL);

  httpServer.on('close', () => {
    clearInterval(heartbeatTimer);
    for (const ws of wss.clients) {
      ws.terminate();
    }
    wss.close();
  });

  return wss;
}
