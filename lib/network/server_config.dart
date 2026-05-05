import 'package:flutter/foundation.dart';

class ServerConfig {
  const ServerConfig._();

  static const String host = kDebugMode ? 'localhost' : 'TODO_PROD_HOST'; // will be set when we have a deployment
  static const int port = kDebugMode ? 3000 : 443;
  static const String path = '/ws';
  static const bool useTls = kDebugMode ? false : true;

  static Uri get serverUri => Uri(
        scheme: useTls ? 'wss' : 'ws',
        host: host,
        port: port,
        path: path,
      );
}
