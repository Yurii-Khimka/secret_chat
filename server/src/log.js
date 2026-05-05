// HARD RULE: This logger MUST NEVER log request bodies, IP addresses, headers,
// room codes, or anything derived from a client connection. It is for
// server-lifecycle events only (startup, shutdown, internal errors). This rule
// is the foundation of the "we cannot read your messages and we don't know who
// you are" promise.

export function info(msg) {
  process.stdout.write(`[${new Date().toISOString()}] [info] ${msg}\n`);
}

export function warn(msg) {
  process.stderr.write(`[${new Date().toISOString()}] [warn] ${msg}\n`);
}
