const tlsCertPath = process.env.TLS_CERT_PATH || null;
const tlsKeyPath = process.env.TLS_KEY_PATH || null;

if ((tlsCertPath && !tlsKeyPath) || (!tlsCertPath && tlsKeyPath)) {
  throw new Error(
    'Both TLS_CERT_PATH and TLS_KEY_PATH must be set together. Only one was provided.'
  );
}

const config = Object.freeze({
  host: process.env.HOST || '127.0.0.1',
  port: parseInt(process.env.PORT || '3000', 10),
  tlsCertPath,
  tlsKeyPath,
  wsPath: process.env.WS_PATH || '/ws',
});

export default config;
