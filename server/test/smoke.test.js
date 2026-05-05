import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { start } from '../src/index.js';

let server;

after(async () => {
  if (server) {
    server.close();
  }
});

test('GET /health returns 200 with version string', async () => {
  server = await start(0);
  const { port } = server.address();

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
  const { port } = server.address();

  const statusCode = await new Promise((resolve, reject) => {
    http.get(`http://127.0.0.1:${port}/nope`, (res) => {
      res.resume();
      resolve(res.statusCode);
    }).on('error', reject);
  });

  assert.equal(statusCode, 404);
});
