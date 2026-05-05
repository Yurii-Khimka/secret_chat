// HARD RULE: This module MUST NEVER log request bodies, IP addresses, headers,
// room codes, frame contents, or anything derived from a client connection.
// No console.log(message). No logging of request.headers,
// request.socket.remoteAddress, or frame contents. Lifecycle counts only
// (startup, shutdown). This rule is the foundation of the "we cannot read your
// messages and we don't know who you are" promise.

import { WebSocketServer } from 'ws';
import config from './config.js';
import { parseMessage, errorMessage, MSG_HELLO, MSG_CREATE_ROOM, MSG_ROOM_CREATED } from './protocol.js';
import { createRoom, removeRoom, AlreadyInRoomError, RoomCodeExhaustedError } from './rooms.js';

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
    ws.send(JSON.stringify({ type: MSG_HELLO, v: '0.1.0' }));

    ws.on('message', (data) => {
      const msg = parseMessage(data);
      if (!msg) {
        ws.send(errorMessage('bad_message', 'malformed or oversized'));
        return;
      }

      switch (msg.type) {
        case MSG_CREATE_ROOM: {
          try {
            const code = createRoom(ws);
            ws.send(JSON.stringify({ type: MSG_ROOM_CREATED, code }));
          } catch (err) {
            if (err instanceof AlreadyInRoomError) {
              ws.send(errorMessage('already_in_room', 'this connection already has a room'));
            } else if (err instanceof RoomCodeExhaustedError) {
              ws.send(errorMessage('exhausted', 'try again'));
            }
          }
          break;
        }
        default:
          ws.send(errorMessage('unknown_type', 'unsupported message type'));
      }
    });

    ws.on('close', () => {
      if (ws.roomCode) {
        removeRoom(ws.roomCode);
      }
    });
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
