export const MSG_HELLO = 'hello';
export const MSG_CREATE_ROOM = 'create_room';
export const MSG_ROOM_CREATED = 'room_created';
export const MSG_ERROR = 'error';

const MAX_FRAME_SIZE = 1024; // 1 KB cap for room-phase messages

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
