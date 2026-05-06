import { randomInt } from 'node:crypto';
import { WORDS } from './wordlist.js';

// ws.roomCode is attached directly to the WebSocket instance rather than a
// parallel Map<ws, code> because the WS lifecycle already drives cleanup.

const rooms = new Map();

export class RoomCodeExhaustedError extends Error {
  constructor() { super('room code space exhausted after retries'); }
}

export class AlreadyInRoomError extends Error {
  constructor() { super('this connection already has a room'); }
}

function generateCode() {
  for (let attempt = 0; attempt < 10; attempt++) {
    const word = WORDS[randomInt(WORDS.length)];
    const num = String(randomInt(10000)).padStart(4, '0');
    const code = `${word}-${num}`;
    if (!rooms.has(code)) return code;
  }
  throw new RoomCodeExhaustedError();
}

export function createRoom(ws, passwordMode = false) {
  if (ws.roomCode) throw new AlreadyInRoomError();
  const code = generateCode();
  ws.roomCode = code;
  rooms.set(code, { creator: ws, joiner: null, passwordMode, createdAt: Date.now(), pairedAt: null });
  return code;
}

export function joinRoom(ws, code) {
  const room = rooms.get(code);
  if (!room) return { ok: false, error: 'not_found' };
  if (room.creator === ws) return { ok: false, error: 'cannot_join_own' };
  if (ws.roomCode) return { ok: false, error: 'already_in_room' };
  if (room.joiner) return { ok: false, error: 'room_full' };

  ws.roomCode = code;
  room.joiner = ws;
  room.pairedAt = Date.now();
  return { ok: true, creator: room.creator };
}

export function leaveRoom(ws) {
  const code = ws.roomCode;
  if (!code) return { removed: false, notify: null };

  const room = rooms.get(code);
  if (!room) {
    ws.roomCode = undefined;
    return { removed: false, notify: null };
  }

  let notify = null;

  if (room.creator === ws) {
    notify = room.joiner || null;
  } else {
    notify = room.creator;
  }

  // Clear roomCode on both parties
  room.creator.roomCode = undefined;
  if (room.joiner) room.joiner.roomCode = undefined;

  rooms.delete(code);
  return { removed: true, notify };
}

export function getPeer(ws) {
  const code = ws.roomCode;
  if (!code) return null;
  const room = rooms.get(code);
  if (!room) return null;
  if (!room.joiner) return null;
  return room.creator === ws ? room.joiner : room.creator;
}

export function getRoom(code) {
  return rooms.get(code);
}

// Test-only: returns all active room codes.
export function _allCodes() {
  return [...rooms.keys()];
}
