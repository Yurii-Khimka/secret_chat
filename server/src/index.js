import { start } from './server.js';
import { info } from './log.js';

const { close } = await start();

function shutdown() {
  info('shutting down');
  close().then(() => process.exit(0));
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
