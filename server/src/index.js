import http from 'node:http';
import { port, host } from './config.js';
import { info } from './log.js';

const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('secret-chat-server v0.1.0');
  } else {
    res.writeHead(404);
    res.end();
  }
});

function shutdown() {
  info('shutting down');
  server.close(() => process.exit(0));
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

export function start(overridePort) {
  const p = overridePort ?? port;
  return new Promise((resolve) => {
    server.listen(p, host, () => {
      info(`server listening on ${host}:${server.address().port}`);
      resolve(server);
    });
  });
}

// When run directly as entry point
const isMain = process.argv[1] && import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/'));
if (isMain) {
  start();
}
