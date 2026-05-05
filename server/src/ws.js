// HARD RULE: This module MUST NEVER log request bodies, IP addresses, headers,
// room codes, frame contents, or anything derived from a client connection.
// No console.log(message). No logging of request.headers,
// request.socket.remoteAddress, or frame contents. Lifecycle counts only
// (startup, shutdown). This rule is the foundation of the "we cannot read your
// messages and we don't know who you are" promise.

import { WebSocketServer } from 'ws';
import config from './config.js';
import {
  parseMessage, errorMessage, CODE_REGEX,
  MSG_HELLO, MSG_CREATE_ROOM, MSG_ROOM_CREATED,
  MSG_JOIN_ROOM, MSG_JOINED, MSG_PEER_JOINED, MSG_PEER_LEFT,
} from './protocol.js';
import { createRoom, joinRoom, leaveRoom, AlreadyInRoomError, RoomCodeExhaustedError } from './rooms.js';

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
        case MSG_JOIN_ROOM: {
          if (typeof msg.code !== 'string' || !CODE_REGEX.test(msg.code)) {
            ws.send(errorMessage('bad_message', 'invalid room code format'));
            break;
          }
          const result = joinRoom(ws, msg.code);
          if (result.ok) {
            ws.send(JSON.stringify({ type: MSG_JOINED, code: msg.code }));
            result.creator.send(JSON.stringify({ type: MSG_PEER_JOINED }));
          } else {
            const reasons = {
              not_found: 'room does not exist',
              room_full: 'room already has two participants',
              cannot_join_own: 'cannot join a room you created',
              already_in_room: 'this connection already has a room',
            };
            ws.send(errorMessage(result.error, reasons[result.error]));
          }
          break;
        }
        default:
          ws.send(errorMessage('unknown_type', 'unsupported message type'));
      }
    });

    ws.on('close', () => {
      const result = leaveRoom(ws);
      if (result.notify) {
        try {
          result.notify.send(JSON.stringify({ type: MSG_PEER_LEFT }));
        } catch { /* peer socket may already be closing */ }
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
