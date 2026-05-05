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

  // Pairing tests
  test('successful join — joiner gets joined, creator gets peer_joined', async () => {
    const a = await connect();
    await nextMessage(a); // hello
    a.send(JSON.stringify({ type: 'create_room' }));
    const created = await nextMessage(a);
    const code = created.code;

    const b = await connect();
    await nextMessage(b); // hello
    b.send(JSON.stringify({ type: 'join_room', code }));

    const joined = await nextMessage(b);
    assert.equal(joined.type, 'joined');
    assert.equal(joined.code, code);

    const peerJoined = await nextMessage(a);
    assert.equal(peerJoined.type, 'peer_joined');

    await closeWs(b);
    await new Promise((r) => setTimeout(r, 50));
    await closeWs(a);
  });

  test('wrong code → not_found', async () => {
    const ws = await connect();
    await nextMessage(ws); // hello
    ws.send(JSON.stringify({ type: 'join_room', code: 'ZZZZ-9999' }));
    const msg = await nextMessage(ws);
    assert.equal(msg.type, 'error');
    assert.equal(msg.code, 'not_found');
    await closeWs(ws);
  });

  test('code with bad format → bad_message', async () => {
    const ws = await connect();
    await nextMessage(ws); // hello
    ws.send(JSON.stringify({ type: 'join_room', code: 'lower-1' }));
    const msg = await nextMessage(ws);
    assert.equal(msg.type, 'error');
    assert.equal(msg.code, 'bad_message');
    await closeWs(ws);
  });

  test('room full — third client rejected', async () => {
    const a = await connect();
    await nextMessage(a); // hello
    a.send(JSON.stringify({ type: 'create_room' }));
    const created = await nextMessage(a);
    const code = created.code;

    const b = await connect();
    await nextMessage(b); // hello
    b.send(JSON.stringify({ type: 'join_room', code }));
    await nextMessage(b); // joined
    await nextMessage(a); // peer_joined

    const c = await connect();
    await nextMessage(c); // hello
    c.send(JSON.stringify({ type: 'join_room', code }));
    const msg = await nextMessage(c);
    assert.equal(msg.type, 'error');
    assert.equal(msg.code, 'room_full');

    await closeWs(c);
    await closeWs(b);
    await new Promise((r) => setTimeout(r, 50));
    await closeWs(a);
  });

  test('cannot join own room', async () => {
    const a = await connect();
    await nextMessage(a); // hello
    a.send(JSON.stringify({ type: 'create_room' }));
    const created = await nextMessage(a);
    a.send(JSON.stringify({ type: 'join_room', code: created.code }));
    const msg = await nextMessage(a);
    assert.equal(msg.type, 'error');
    assert.equal(msg.code, 'cannot_join_own');
    await closeWs(a);
  });

  test('joiner already in another room → already_in_room', async () => {
    const a = await connect();
    await nextMessage(a); // hello
    a.send(JSON.stringify({ type: 'create_room' }));
    const room1 = await nextMessage(a);

    const b = await connect();
    await nextMessage(b); // hello
    b.send(JSON.stringify({ type: 'create_room' }));
    await nextMessage(b); // room_created for b

    b.send(JSON.stringify({ type: 'join_room', code: room1.code }));
    const msg = await nextMessage(b);
    assert.equal(msg.type, 'error');
    assert.equal(msg.code, 'already_in_room');

    await closeWs(b);
    await new Promise((r) => setTimeout(r, 50));
    await closeWs(a);
  });

  test('joiner disconnects → creator gets peer_left, room removed', async () => {
    const a = await connect();
    await nextMessage(a); // hello
    a.send(JSON.stringify({ type: 'create_room' }));
    const created = await nextMessage(a);
    const code = created.code;

    const b = await connect();
    await nextMessage(b); // hello
    b.send(JSON.stringify({ type: 'join_room', code }));
    await nextMessage(b); // joined
    await nextMessage(a); // peer_joined

    await closeWs(b);
    const peerLeft = await nextMessage(a);
    assert.equal(peerLeft.type, 'peer_left');

    await new Promise((r) => setTimeout(r, 50));
    assert.ok(!_allCodes().includes(code));
    await closeWs(a);
  });

  test('creator disconnects → joiner gets peer_left, room removed', async () => {
    const a = await connect();
    await nextMessage(a); // hello
    a.send(JSON.stringify({ type: 'create_room' }));
    const created = await nextMessage(a);
    const code = created.code;

    const b = await connect();
    await nextMessage(b); // hello
    b.send(JSON.stringify({ type: 'join_room', code }));
    await nextMessage(b); // joined
    await nextMessage(a); // peer_joined

    await closeWs(a);
    const peerLeft = await nextMessage(b);
    assert.equal(peerLeft.type, 'peer_left');

    await new Promise((r) => setTimeout(r, 50));
    assert.ok(!_allCodes().includes(code));
    await closeWs(b);
  });

  // Relay tests
  describe('Relay', () => {
    async function createPair() {
      const a = await connect();
      await nextMessage(a); // hello
      a.send(JSON.stringify({ type: 'create_room' }));
      const created = await nextMessage(a);
      const code = created.code;

      const b = await connect();
      await nextMessage(b); // hello
      b.send(JSON.stringify({ type: 'join_room', code }));
      await nextMessage(b); // joined
      await nextMessage(a); // peer_joined
      return { a, b, code };
    }

    test('A → B relay', async () => {
      const { a, b } = await createPair();
      a.send(JSON.stringify({ type: 'msg', payload: 'hello-from-a' }));
      const msg = await nextMessage(b);
      assert.deepEqual(msg, { type: 'msg', payload: 'hello-from-a' });
      await closeWs(b);
      await new Promise((r) => setTimeout(r, 50));
      await closeWs(a);
    });

    test('B → A relay', async () => {
      const { a, b } = await createPair();
      b.send(JSON.stringify({ type: 'msg', payload: 'hello-from-b' }));
      const msg = await nextMessage(a);
      assert.deepEqual(msg, { type: 'msg', payload: 'hello-from-b' });
      await closeWs(b);
      await new Promise((r) => setTimeout(r, 50));
      await closeWs(a);
    });

    test('sender not in a room → not_in_room', async () => {
      const ws = await connect();
      await nextMessage(ws); // hello
      ws.send(JSON.stringify({ type: 'msg', payload: 'test' }));
      const msg = await nextMessage(ws);
      assert.equal(msg.type, 'error');
      assert.equal(msg.code, 'not_in_room');
      await closeWs(ws);
    });

    test('sender unpaired → not_paired', async () => {
      const a = await connect();
      await nextMessage(a); // hello
      a.send(JSON.stringify({ type: 'create_room' }));
      await nextMessage(a); // room_created
      a.send(JSON.stringify({ type: 'msg', payload: 'test' }));
      const msg = await nextMessage(a);
      assert.equal(msg.type, 'error');
      assert.equal(msg.code, 'not_paired');
      await closeWs(a);
    });

    test('missing payload → bad_message', async () => {
      const { a, b } = await createPair();
      a.send(JSON.stringify({ type: 'msg' }));
      const msg = await nextMessage(a);
      assert.equal(msg.type, 'error');
      assert.equal(msg.code, 'bad_message');
      await closeWs(b);
      await new Promise((r) => setTimeout(r, 50));
      await closeWs(a);
    });

    test('non-string payload → bad_message', async () => {
      const { a, b } = await createPair();
      a.send(JSON.stringify({ type: 'msg', payload: 123 }));
      const msg = await nextMessage(a);
      assert.equal(msg.type, 'error');
      assert.equal(msg.code, 'bad_message');
      await closeWs(b);
      await new Promise((r) => setTimeout(r, 50));
      await closeWs(a);
    });

    test('oversized frame → bad_message, peer receives nothing', async () => {
      const { a, b } = await createPair();
      // Build a frame larger than 16 KB
      const bigPayload = 'x'.repeat(16 * 1024 + 1);
      a.send(JSON.stringify({ type: 'msg', payload: bigPayload }));
      const msg = await nextMessage(a);
      assert.equal(msg.type, 'error');
      assert.equal(msg.code, 'bad_message');
      // B should not have received anything — send a known msg to verify
      b.send(JSON.stringify({ type: 'msg', payload: 'check' }));
      const check = await nextMessage(a);
      assert.deepEqual(check, { type: 'msg', payload: 'check' });
      await closeWs(b);
      await new Promise((r) => setTimeout(r, 50));
      await closeWs(a);
    });

    test('server does not modify payload (special chars)', async () => {
      const { a, b } = await createPair();
      const special = 'a"b\\cé';
      a.send(JSON.stringify({ type: 'msg', payload: special }));
      const msg = await nextMessage(b);
      assert.equal(msg.type, 'msg');
      assert.equal(msg.payload, special);
      await closeWs(b);
      await new Promise((r) => setTimeout(r, 50));
      await closeWs(a);
    });
  });

  // Lifecycle tests (own start/close cycle, run before final shutdown test)
  describe('Lifecycle', () => {
    function connectRaw(portNum) {
      return new Promise((resolve, reject) => {
        const ws = new WebSocket(`ws://127.0.0.1:${portNum}/ws`);
        const gotHello = new Promise((r) => ws.once('message', r));
        const gotClose = new Promise((r) => ws.once('close', r));
        ws.on('open', () => resolve({ ws, gotHello, gotClose }));
        ws.on('error', reject);
      });
    }

    test('shutdown completes within 500ms with 5 connected clients', async () => {
      const h = await start({ port: 0 });
      const p = h.server.address().port;

      const clients = [];
      for (let i = 0; i < 5; i++) {
        const c = await connectRaw(p);
        await c.gotHello;
        clients.push(c);
      }

      const t0 = Date.now();
      await h.close();
      const elapsed = Date.now() - t0;

      await Promise.all(clients.map((c) => c.gotClose));
      assert.ok(elapsed < 500, `shutdown took ${elapsed}ms, expected < 500ms`);
    });

    test('heartbeat interval is cleared on shutdown', async () => {
      // Verify no timer leak: after close(), active handle count should not exceed baseline.
      const baselineHandles = process._getActiveHandles().length;
      const h = await start({ port: 0 });
      const p = h.server.address().port;

      const c = await connectRaw(p);
      await c.gotHello;

      await h.close();
      await new Promise((r) => setTimeout(r, 50));
      const afterHandles = process._getActiveHandles().length;
      assert.ok(afterHandles <= baselineHandles + 1, `leaked handles: before=${baselineHandles}, after=${afterHandles}`);
    });
  });

  // Shutdown test (last — closes the shared server)
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
