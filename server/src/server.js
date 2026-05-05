import http from 'node:http';
import https from 'node:https';
import fs from 'node:fs';
import config from './config.js';
import { info } from './log.js';
import { attachWebSocket } from './ws.js';

function handleRequest(req, res) {
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('secret-chat-server v0.1.0');
  } else {
    res.writeHead(404);
    res.end();
  }
}

export function start(overrides = {}) {
  const host = overrides.host ?? config.host;
  const port = overrides.port ?? config.port;
  const wsPath = config.wsPath;

  let server;
  let protocol;

  if (config.tlsCertPath && config.tlsKeyPath) {
    const cert = fs.readFileSync(config.tlsCertPath);
    const key = fs.readFileSync(config.tlsKeyPath);
    server = https.createServer({ cert, key }, handleRequest);
    protocol = 'https';
  } else {
    server = http.createServer(handleRequest);
    protocol = 'http';
  }

  attachWebSocket(server);

  // Track connections for forceful shutdown
  const connections = new Set();
  server.on('connection', (socket) => {
    connections.add(socket);
    socket.on('close', () => connections.delete(socket));
  });

  return new Promise((resolve) => {
    server.listen(port, host, () => {
      const actualPort = server.address().port;
      info(`server listening on ${protocol}://${host}:${actualPort} (ws path: ${wsPath})`);
      resolve({
        server,
        close: () => new Promise((res) => {
          for (const socket of connections) {
            socket.destroy();
          }
          server.close(res);
        }),
      });
    });
  });
}
