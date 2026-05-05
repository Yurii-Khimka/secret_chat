import { test, after, describe } from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { WebSocket } from 'ws';
import { start } from '../src/server.js';

let handle;
let port;

after(async () => {
  if (handle) {
    await handle.close();
  }
});

describe('HTTP', () => {
  test('GET /health returns 200 with version string', async () => {
    handle = await start({ port: 0 });
    port = handle.server.address().port;

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
});

describe('WebSocket', () => {
  test('connects on /ws and receives hello frame', async () => {
    const msg = await new Promise((resolve, reject) => {
      const ws = new WebSocket(`ws://127.0.0.1:${port}/ws`);
      ws.on('message', (data) => {
        resolve(JSON.parse(data.toString()));
        ws.close();
      });
      ws.on('error', reject);
    });

    assert.deepEqual(msg, { type: 'hello', v: '0.1.0' });
  });

  test('wrong path is rejected', async () => {
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

  test('server closes cleanly with open ws client', async () => {
    const ws = new WebSocket(`ws://127.0.0.1:${port}/ws`);
    await new Promise((resolve) => ws.on('open', resolve));

    const closed = new Promise((resolve) => ws.on('close', resolve));
    await handle.close();
    handle = null;

    const timer = setTimeout(() => { throw new Error('close timed out'); }, 1000);
    await closed;
    clearTimeout(timer);
  });
});
