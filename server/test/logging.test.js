import { test, describe, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { WebSocket } from 'ws';
import { start } from '../src/server.js';

function connect(port) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`ws://127.0.0.1:${port}/ws`);
    const messages = [];
    let waiting = null;
    ws.on('message', (data) => {
      const parsed = JSON.parse(data.toString());
      if (waiting) { const cb = waiting; waiting = null; cb(parsed); }
      else messages.push(parsed);
    });
    ws.nextMessage = () => {
      if (messages.length > 0) return Promise.resolve(messages.shift());
      return new Promise((r) => { waiting = r; });
    };
    ws.on('open', () => resolve(ws));
    ws.on('error', reject);
  });
}

function closeWs(ws) {
  return new Promise((resolve) => {
    if (ws.readyState === WebSocket.CLOSED) { resolve(); return; }
    ws.on('close', resolve);
    ws.close();
  });
}

describe('Logging contract', { concurrency: false }, () => {
  test('lifecycle-only baseline: startup produces exactly one app log line', async () => {
    const appLogs = [];
    const appErrs = [];
    const origOut = process.stdout.write.bind(process.stdout);
    const origErr = process.stderr.write.bind(process.stderr);
    const appLogPattern = /^\[\d{4}-\d{2}-\d{2}T/;
    process.stdout.write = (chunk) => {
      const str = chunk.toString();
      if (appLogPattern.test(str)) appLogs.push(str);
      return origOut(chunk);
    };
    process.stderr.write = (chunk) => {
      const str = chunk.toString();
      if (appLogPattern.test(str)) appErrs.push(str);
      return origErr(chunk);
    };

    try {
      const handle = await start({ port: 0 });
      assert.equal(appLogs.length, 1);
      assert.match(appLogs[0], /server listening on/);
      assert.equal(appErrs.length, 0);

      await handle.close();
      // No additional app logs from close (shutdown log is only in index.js)
      assert.equal(appErrs.length, 0);
    } finally {
      process.stdout.write = origOut;
      process.stderr.write = origErr;
    }
  });

  test('data-path silence: full session produces zero data-path logs', async () => {
    const appLogs = [];
    const origOut = process.stdout.write.bind(process.stdout);
    const origErr = process.stderr.write.bind(process.stderr);
    const appLogPattern = /^\[\d{4}-\d{2}-\d{2}T/;
    process.stdout.write = (chunk) => {
      const str = chunk.toString();
      if (appLogPattern.test(str)) appLogs.push(str);
      return origOut(chunk);
    };
    process.stderr.write = (chunk) => {
      const str = chunk.toString();
      if (appLogPattern.test(str)) appLogs.push(str);
      return origErr(chunk);
    };

    let handle;
    try {
      handle = await start({ port: 0 });
      const port = handle.server.address().port;

      // Clear startup line
      assert.equal(appLogs.length, 1);
      appLogs.splice(0, appLogs.length);

      // --- Open-mode session ---
      const a = await connect(port);
      await a.nextMessage(); // hello
      a.send(JSON.stringify({ type: 'create_room' }));
      const created = await a.nextMessage();
      const code = created.code;

      const b = await connect(port);
      await b.nextMessage(); // hello
      b.send(JSON.stringify({ type: 'join_room', code }));
      await b.nextMessage(); // joined
      await a.nextMessage(); // peer_joined

      // Exchange 3 plaintext messages each
      for (let i = 0; i < 3; i++) {
        a.send(JSON.stringify({ type: 'msg', text: `secret-from-a-${i}` }));
        await b.nextMessage();
        b.send(JSON.stringify({ type: 'msg', text: `secret-from-b-${i}` }));
        await a.nextMessage();
      }

      await closeWs(b);
      await a.nextMessage(); // peer_left
      await closeWs(a);

      // --- Password-mode session ---
      const c = await connect(port);
      await c.nextMessage(); // hello
      c.send(JSON.stringify({ type: 'create_room', password_mode: true }));
      const created2 = await c.nextMessage();
      const code2 = created2.code;

      const d = await connect(port);
      await d.nextMessage(); // hello
      d.send(JSON.stringify({ type: 'join_room', code: code2 }));
      await d.nextMessage(); // joined
      await c.nextMessage(); // peer_joined

      // Exchange 3 ciphertext messages each
      for (let i = 0; i < 3; i++) {
        c.send(JSON.stringify({ type: 'msg', ciphertext: `cipher-c-${i}`, nonce: `nonce-c-${i}` }));
        await d.nextMessage();
        d.send(JSON.stringify({ type: 'msg', ciphertext: `cipher-d-${i}`, nonce: `nonce-d-${i}` }));
        await c.nextMessage();
      }

      await closeWs(d);
      await c.nextMessage(); // peer_left
      await closeWs(c);

      // --- Malformed frames ---
      const e = await connect(port);
      await e.nextMessage(); // hello
      e.send(JSON.stringify({ type: 'create_room' }));
      const created3 = await e.nextMessage();

      const f = await connect(port);
      await f.nextMessage(); // hello
      f.send(JSON.stringify({ type: 'join_room', code: created3.code }));
      await f.nextMessage(); // joined
      await e.nextMessage(); // peer_joined

      // Oversized text
      e.send(JSON.stringify({ type: 'msg', text: 'x'.repeat(4097) }));
      await e.nextMessage(); // error

      // Both text and ciphertext
      e.send(JSON.stringify({ type: 'msg', text: 'hi', ciphertext: 'abc', nonce: 'def' }));
      await e.nextMessage(); // error

      // Unknown type
      e.send(JSON.stringify({ type: 'nonsense_type' }));
      await e.nextMessage(); // error

      await closeWs(f);
      await e.nextMessage(); // peer_left
      await closeWs(e);

      await new Promise((r) => setTimeout(r, 50));

      // ASSERT: zero data-path app logs
      assert.equal(appLogs.length, 0, `unexpected app logs: ${JSON.stringify(appLogs)}`);

      // Verify none of the client data leaked
      const allOutput = appLogs.join('');
      assert.ok(!allOutput.includes(code), 'room code leaked');
      assert.ok(!allOutput.includes('secret-from-a'), 'plaintext leaked');
      assert.ok(!allOutput.includes('cipher-c'), 'ciphertext leaked');
      assert.ok(!allOutput.includes('nonce-c'), 'nonce leaked');
    } finally {
      process.stdout.write = origOut;
      process.stderr.write = origErr;
      if (handle) await handle.close();
    }
  });

  test('error frames do not leak client input to stdio', async () => {
    const appLogs = [];
    const origOut = process.stdout.write.bind(process.stdout);
    const origErr = process.stderr.write.bind(process.stderr);
    // Only capture lines from our logger (format: [ISO] [level] msg)
    const appLogPattern = /^\[\d{4}-\d{2}-\d{2}T/;
    process.stdout.write = (chunk) => {
      const str = chunk.toString();
      if (appLogPattern.test(str)) appLogs.push(str);
      return origOut(chunk);
    };
    process.stderr.write = (chunk) => {
      const str = chunk.toString();
      if (appLogPattern.test(str)) appLogs.push(str);
      return origErr(chunk);
    };

    let handle;
    try {
      handle = await start({ port: 0 });
      const port = handle.server.address().port;
      // Clear startup log
      appLogs.splice(0, appLogs.length);

      const ws = await connect(port);
      await ws.nextMessage(); // hello

      // Send join_room with a specific code that should not appear in logs
      ws.send(JSON.stringify({ type: 'join_room', code: 'WOLF-9999' }));
      const errMsg = await ws.nextMessage();
      assert.equal(errMsg.type, 'error');
      assert.equal(errMsg.code, 'not_found');
      // Reason is a fixed string, never the client's code
      assert.ok(!errMsg.reason.includes('WOLF-9999'));

      await closeWs(ws);
      await new Promise((r) => setTimeout(r, 50));

      // No app logs on data path
      assert.equal(appLogs.length, 0, `unexpected app logs: ${JSON.stringify(appLogs)}`);
      const allOutput = appLogs.join('');
      assert.ok(!allOutput.includes('WOLF-9999'));
    } finally {
      process.stdout.write = origOut;
      process.stderr.write = origErr;
      if (handle) await handle.close();
    }
  });

  test('no .remoteAddress access in source files (outside comments)', () => {
    const srcDir = path.resolve(import.meta.dirname, '../src');
    const files = fs.readdirSync(srcDir).filter((f) => f.endsWith('.js'));

    for (const file of files) {
      const content = fs.readFileSync(path.join(srcDir, file), 'utf8');
      const lines = content.split('\n');
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        // Skip comment lines
        if (line.startsWith('//') || line.startsWith('*') || line.startsWith('/*')) continue;
        assert.ok(
          !line.includes('.remoteAddress'),
          `${file}:${i + 1} contains .remoteAddress access`
        );
        assert.ok(
          !line.includes('x-forwarded-for') && !line.includes('x-real-ip'),
          `${file}:${i + 1} contains PII header access`
        );
      }
    }
  });
});
