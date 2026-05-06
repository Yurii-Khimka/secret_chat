import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'server_config.dart';
import 'protocol.dart';

enum ChatConnectionState { idle, connecting, connected, paired, closed, error }

class IncomingMessage {
  IncomingMessage({required this.text, required this.fromSelf, required this.at});
  final String text;
  final bool fromSelf;
  final DateTime at;
}

class ChatClient extends ChangeNotifier {
  ChatConnectionState _state = ChatConnectionState.idle;
  String? _roomCode;
  String? _lastError;
  bool _passwordMode = false;
  bool? _isHost;
  String? _localNickname;
  final List<IncomingMessage> _messages = [];

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  ChatConnectionState get state => _state;
  String? get roomCode => _roomCode;
  String? get lastError => _lastError;
  bool get passwordMode => _passwordMode;
  bool? get isHost => _isHost;
  String? get localNickname => _localNickname;
  List<IncomingMessage> get messages => List.unmodifiable(_messages);

  void _setState(ChatConnectionState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> _connect() async {
    if (_channel != null) return;
    _setState(ChatConnectionState.connecting);
    try {
      final channel = WebSocketChannel.connect(ServerConfig.serverUri);
      await channel.ready;
      _channel = channel;
      // no client data on this path
      _subscription = channel.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _lastError = 'connection_failed';
      _setState(ChatConnectionState.error);
    }
  }

  void _onData(dynamic data) {
    if (data is! String) return;
    final msg = parseFrame(data);
    if (msg == null) return;

    switch (msg) {
      case HelloMsg():
        if (kDebugMode) debugPrint('[chat] connected');
      case RoomCreatedMsg():
        _roomCode = msg.code;
        _passwordMode = msg.passwordMode;
        _setState(ChatConnectionState.connected);
      case JoinedMsg():
        _roomCode = msg.code;
        _passwordMode = msg.passwordMode;
        _setState(ChatConnectionState.paired);
      case PeerJoinedMsg():
        _setState(ChatConnectionState.paired);
      case PeerLeftMsg():
        _setState(ChatConnectionState.closed);
        close();
      case MsgMsg():
        _messages.add(IncomingMessage(
          text: msg.payload,
          fromSelf: false,
          at: DateTime.now(),
        ));
        notifyListeners();
      case ErrorMsg():
        _lastError = msg.code;
        _setState(ChatConnectionState.error);
    }
  }

  void _onError(Object error) {
    if (_state == ChatConnectionState.idle || _state == ChatConnectionState.closed) return;
    _lastError = 'connection_error';
    _setState(ChatConnectionState.error);
  }

  void _onDone() {
    if (_state == ChatConnectionState.idle || _state == ChatConnectionState.closed) return;
    _lastError = 'connection_lost';
    _setState(ChatConnectionState.closed);
  }

  Future<void> createRoom({bool passwordMode = false, String? nickname}) async {
    _lastError = null;
    _isHost = true;
    _localNickname = nickname?.trim().isNotEmpty == true ? nickname!.trim() : null;
    await _connect();
    if (_state == ChatConnectionState.error) return;
    _channel?.sink.add(createRoomFrame(passwordMode: passwordMode));
  }

  Future<void> joinRoom(String code, {String? nickname}) async {
    if (!kCodeRegex.hasMatch(code)) {
      _lastError = 'bad_message';
      _setState(ChatConnectionState.error);
      return;
    }
    _lastError = null;
    _isHost = false;
    _localNickname = nickname?.trim().isNotEmpty == true ? nickname!.trim() : null;
    await _connect();
    if (_state == ChatConnectionState.error) return;
    _channel?.sink.add(joinRoomFrame(code));
  }

  Future<void> sendMessage(String text) async {
    if (_state != ChatConnectionState.paired) return;
    if (text.isEmpty) return;
    _messages.add(IncomingMessage(
      text: text,
      fromSelf: true,
      at: DateTime.now(),
    ));
    notifyListeners();
    _channel?.sink.add(msgFrame(text));
  }

  Future<void> close() async {
    final channel = _channel;
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    _roomCode = null;
    _lastError = null;
    _passwordMode = false;
    _isHost = null;
    _localNickname = null;
    _messages.clear();
    _state = ChatConnectionState.idle;
    try {
      await channel?.sink.close();
    } catch (_) {}
    notifyListeners();
  }
}
