import { start } from './server.js';
import { info, warn } from './log.js';

const { close } = await start();

function shutdown() {
  info('shutting down');
  const hardTimeout = setTimeout(() => {
    warn('shutdown timed out after 5 s — forcing exit');
    process.exit(1);
  }, 5000);
  hardTimeout.unref();
  close().then(() => process.exit(0));
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
