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
  MSG_MSG,
} from './protocol.js';
import { createRoom, joinRoom, leaveRoom, getPeer, getRoom, AlreadyInRoomError, RoomCodeExhaustedError } from './rooms.js';

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
          // Validate password_mode: absent → false, boolean → pass through, else reject.
          let passwordMode = false;
          if ('password_mode' in msg) {
            if (typeof msg.password_mode !== 'boolean') {
              ws.send(errorMessage('bad_request', 'invalid password_mode'));
              break;
            }
            passwordMode = msg.password_mode;
          }
          try {
            const code = createRoom(ws, passwordMode);
            // Do not log passwordMode alongside code — see zero-data policy.
            ws.send(JSON.stringify({ type: MSG_ROOM_CREATED, code, password_mode: passwordMode }));
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
            const room = getRoom(msg.code);
            ws.send(JSON.stringify({ type: MSG_JOINED, code: msg.code, password_mode: room.passwordMode }));
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
        // RELAY: silent path. Do not add logging here.
        case MSG_MSG: {
          if (typeof msg.payload !== 'string' || msg.payload.length === 0) {
            ws.send(errorMessage('bad_message', 'payload required'));
            break;
          }
          if (!ws.roomCode) {
            ws.send(errorMessage('not_in_room', 'create or join a room first'));
            break;
          }
          const peer = getPeer(ws);
          if (!peer) {
            ws.send(errorMessage('not_paired', 'waiting for a peer to join'));
            break;
          }
          try { peer.send(JSON.stringify({ type: MSG_MSG, payload: msg.payload })); } catch { /* noop */ }
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

  function teardown() {
    clearInterval(heartbeatTimer);
    for (const ws of wss.clients) {
      ws.terminate();
    }
    wss.close();
  }

  httpServer.on('close', teardown);

  return { wss, teardown };
}
