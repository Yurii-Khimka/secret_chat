export const MSG_HELLO = 'hello';
export const MSG_CREATE_ROOM = 'create_room';
export const MSG_ROOM_CREATED = 'room_created';
export const MSG_JOIN_ROOM = 'join_room';
export const MSG_JOINED = 'joined';
export const MSG_PEER_JOINED = 'peer_joined';
export const MSG_PEER_LEFT = 'peer_left';
export const MSG_MSG = 'msg';
export const MSG_ERROR = 'error';

export const CODE_REGEX = /^[A-Z]{3,5}-\d{4}$/;

// 16 KB: fits AES-256-GCM ciphertext + base64 + nonce + tag for typical chat messages.
const MAX_FRAME_SIZE = 16 * 1024;

export function parseMessage(raw) {
  const str = typeof raw === 'string' ? raw : raw.toString();
  if (str.length > MAX_FRAME_SIZE) return null;

  let parsed;
  try {
    parsed = JSON.parse(str);
  } catch {
    return null;
  }

  if (!parsed || typeof parsed !== 'object') return null;
  if (typeof parsed.type !== 'string') return null;

  return parsed;
}

// Never echo client-supplied content into reason — only fixed server strings.
export function errorMessage(code, reason) {
  return JSON.stringify({ type: MSG_ERROR, code, reason });
}
