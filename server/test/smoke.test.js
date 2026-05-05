import { test, after, describe, before } from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { WebSocket } from 'ws';
import { start } from '../src/server.js';
import { _allCodes } from '../src/rooms.js';

describe('secret-chat-server', { concurrency: false }, () => {
  let handle;
  let port;

  function connect() {
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

  function nextMessage(ws) {
    return ws.nextMessage();
  }

  function closeWs(ws) {
    return new Promise((resolve) => {
      if (ws.readyState === WebSocket.CLOSED) { resolve(); return; }
      ws.on('close', resolve);
      ws.close();
    });
  }

  before(async () => {
    handle = await start({ port: 0 });
    port = handle.server.address().port;
  });

  after(async () => {
    if (handle) {
      await handle.close();
    }
  });

  // HTTP tests
  test('GET /health returns 200 with version string', async () => {
    const body = await new Promise((resolve, reject) => {
      http.get(`http://127.0.0.1:${port}/health`, (res) => {
        assert.equal(res.statusCode, 200);
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => resolve(data));
      }).on('error', reject);
    });
    assert.equal(body, 'secret-chat-server v0.1.0');
  });

  test('GET /nope returns 404', async () => {
    const statusCode = await new Promise((resolve, reject) => {
      http.get(`http://127.0.0.1:${port}/nope`, (res) => {
        res.resume();
        resolve(res.statusCode);
      }).on('error', reject);
    });
    assert.equal(statusCode, 404);
  });

  // WebSocket tests
  test('WS connects on /ws and receives hello frame', async () => {
    const ws = await connect();
    const msg = await nextMessage(ws);
    assert.deepEqual(msg, { type: 'hello', v: '0.1.0' });
    await closeWs(ws);
  });

  test('WS wrong path is rejected', async () => {
    await new Promise((resolve, reject) => {
      const ws = new WebSocket(`ws://127.0.0.1:${port}/nope`);
      ws.on('open', () => reject(new Error('should not have opened')));
      ws.on('error', () => resolve());
      ws.on('unexpected-response', () => {
        ws.close();
        resolve();
      });
    });
  });

  // Room tests
  test('create_room returns a well-formed code', async () => {
    const ws = await connect();
    await nextMessage(ws); // hello
    ws.send(JSON.stringify({ type: 'create_room' }));
    const msg = await nextMessage(ws);
    assert.equal(msg.type, 'room_created');
    assert.match(msg.code, /^[A-Z]{3,5}-\d{4}$/);
    await closeWs(ws);
  });

  test('second create_room on same socket → already_in_room', async () => {
    const ws = await connect();
    await nextMessage(ws); // hello
    ws.send(JSON.stringify({ type: 'create_room' }));
    await nextMessage(ws); // room_created
    ws.send(JSON.stringify({ type: 'create_room' }));
    const msg = await nextMessage(ws);
    assert.equal(msg.type, 'error');
    assert.equal(msg.code, 'already_in_room');
    await closeWs(ws);
  });

  test('bad JSON → bad_message', async () => {
    const ws = await connect();
    await nextMessage(ws); // hello
    ws.send('not json');
    const msg = await nextMessage(ws);
    assert.equal(msg.type, 'error');
    assert.equal(msg.code, 'bad_message');
    await closeWs(ws);
  });

  test('unknown type → unknown_type', async () => {
    const ws = await connect();
    await nextMessage(ws); // hello
    ws.send(JSON.stringify({ type: 'foo' }));
    const msg = await nextMessage(ws);
    assert.equal(msg.type, 'error');
    assert.equal(msg.code, 'unknown_type');
    await closeWs(ws);
  });

  test('oversized frame → bad_message', async () => {
    const ws = await connect();
    await nextMessage(ws); // hello
    ws.send('x'.repeat(2048));
    const msg = await nextMessage(ws);
    assert.equal(msg.type, 'error');
    assert.equal(msg.code, 'bad_message');
    await closeWs(ws);
  });

  test('disconnect removes the room', async () => {
    const ws = await connect();
    await nextMessage(ws); // hello
    ws.send(JSON.stringify({ type: 'create_room' }));
    const msg = await nextMessage(ws);
    const code = msg.code;
    assert.ok(_allCodes().includes(code));

    await closeWs(ws);
    await new Promise((r) => setTimeout(r, 50));
    assert.ok(!_allCodes().includes(code));
  });

  // Shutdown test (last)
  test('server closes cleanly with open ws client', async () => {
    const ws = await connect();
    await nextMessage(ws); // hello

    const closed = new Promise((resolve) => ws.on('close', resolve));
    await handle.close();
    handle = null;

    const timer = setTimeout(() => { throw new Error('close timed out'); }, 1000);
    await closed;
    clearTimeout(timer);
  });
});
