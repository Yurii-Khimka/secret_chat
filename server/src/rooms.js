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

export function createRoom(ws) {
  if (ws.roomCode) throw new AlreadyInRoomError();
  const code = generateCode();
  ws.roomCode = code;
  rooms.set(code, { creator: ws, createdAt: Date.now() });
  return code;
}

export function removeRoom(code) {
  const entry = rooms.get(code);
  if (!entry) return;
  if (entry.creator.roomCode === code) {
    entry.creator.roomCode = undefined;
  }
  rooms.delete(code);
}

export function getRoom(code) {
  return rooms.get(code);
}

// Test-only: returns all active room codes.
export function _allCodes() {
  return [...rooms.keys()];
}
