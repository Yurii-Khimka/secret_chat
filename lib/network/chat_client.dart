import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'server_config.dart';
import 'protocol.dart';
import 'crypto.dart';

enum ChatConnectionState { idle, connecting, connected, paired, closed, error }

class ChatMessage {
  ChatMessage({required this.text, required this.fromSelf, required this.at, this.decryptFailed = false});
  final String text;
  final bool fromSelf;
  final DateTime at;
  final bool decryptFailed;
}

class _PendingCiphertext {
  _PendingCiphertext({required this.ciphertext, required this.nonce, required this.at});
  final String ciphertext;
  final String nonce;
  final DateTime at;
}

class ChatClient extends ChangeNotifier {
  ChatConnectionState _state = ChatConnectionState.idle;
  String? _roomCode;
  String? _lastError;
  bool _passwordMode = false;
  bool? _isHost;
  String? _localNickname;
  final List<ChatMessage> _messages = [];

  Uint8List? _key;
  bool _mismatchDetected = false;
  final List<_PendingCiphertext> _pendingDecrypt = [];

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  ChatConnectionState get state => _state;
  String? get roomCode => _roomCode;
  String? get lastError => _lastError;
  bool get passwordMode => _passwordMode;
  bool? get isHost => _isHost;
  String? get localNickname => _localNickname;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get hasKey => _key != null;
  bool get mismatchDetected => _mismatchDetected;

  void _setState(ChatConnectionState s) {
    _state = s;
    notifyListeners();
  }

  static const Duration _connectTimeout = Duration(seconds: 8);

  @visibleForTesting
  static Duration get connectTimeout => _connectTimeout;

  Future<void> _connect() async {
    if (_channel != null) return;
    _setState(ChatConnectionState.connecting);
    final channel = WebSocketChannel.connect(ServerConfig.serverUri);
    try {
      await channel.ready.timeout(_connectTimeout);
    } on TimeoutException {
      try { await channel.sink.close(); } catch (_) {}
      _lastError = 'connect_timeout';
      _setState(ChatConnectionState.error);
      return;
    } catch (e) {
      try { await channel.sink.close(); } catch (_) {}
      _lastError = 'connection_failed';
      _setState(ChatConnectionState.error);
      return;
    }
    _channel = channel;
    _subscription = channel.stream.listen(_onData, onError: _onError, onDone: _onDone);
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
        _handleIncomingMsg(msg);
      case ErrorMsg():
        _lastError = msg.code;
        _setState(ChatConnectionState.error);
    }
  }

  void _handleIncomingMsg(MsgMsg msg) {
    if (!_passwordMode) {
      // Open mode
      if (msg.text != null) {
        _messages.add(ChatMessage(
          text: msg.text!,
          fromSelf: false,
          at: DateTime.now(),
        ));
        notifyListeners();
      }
      return;
    }

    // Password mode
    if (msg.text != null) {
      return;
    }

    if (msg.ciphertext != null && msg.nonce != null) {
      if (_key == null) {
        _pendingDecrypt.add(_PendingCiphertext(
          ciphertext: msg.ciphertext!,
          nonce: msg.nonce!,
          at: DateTime.now(),
        ));
      } else {
        _decryptAndEmit(msg.ciphertext!, msg.nonce!);
      }
    }
  }

  Future<void> _decryptAndEmit(String ciphertext, String nonce) async {
    final plaintext = await decryptMessage(
      ciphertextBase64: ciphertext,
      nonceBase64: nonce,
      key: _key!,
    );
    if (plaintext != null) {
      _messages.add(ChatMessage(
        text: plaintext,
        fromSelf: false,
        at: DateTime.now(),
      ));
    } else {
      _mismatchDetected = true;
      _messages.add(ChatMessage(
        text: '',
        fromSelf: false,
        at: DateTime.now(),
        decryptFailed: true,
      ));
    }
    notifyListeners();
  }

  Future<void> _drainPending() async {
    final pending = List<_PendingCiphertext>.from(_pendingDecrypt);
    _pendingDecrypt.clear();
    for (final p in pending) {
      final plaintext = await decryptMessage(
        ciphertextBase64: p.ciphertext,
        nonceBase64: p.nonce,
        key: _key!,
      );
      if (plaintext != null) {
        _messages.add(ChatMessage(
          text: plaintext,
          fromSelf: false,
          at: p.at,
        ));
      } else {
        _mismatchDetected = true;
        _messages.add(ChatMessage(
          text: '',
          fromSelf: false,
          at: p.at,
          decryptFailed: true,
        ));
      }
    }
    notifyListeners();
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

    if (!_passwordMode) {
      // Open mode: send plaintext
      _messages.add(ChatMessage(
        text: text,
        fromSelf: true,
        at: DateTime.now(),
      ));
      notifyListeners();
      _channel?.sink.add(msgTextFrame(text));
      return;
    }

    // Password mode
    if (_key == null) {
      // First message is the phrase — derive key
      _key = await deriveKey(phrase: text, roomCode: _roomCode!);

      // Drain pending (insert before local message)
      await _drainPending();

      // Encrypt the phrase itself and send
      final encrypted = await encryptMessage(plaintext: text, key: _key!);
      _messages.add(ChatMessage(
        text: text,
        fromSelf: true,
        at: DateTime.now(),
      ));
      notifyListeners();
      _channel?.sink.add(msgCipherFrame(ciphertext: encrypted.ciphertext, nonce: encrypted.nonce));
    } else {
      // Subsequent messages
      final encrypted = await encryptMessage(plaintext: text, key: _key!);
      _messages.add(ChatMessage(
        text: text,
        fromSelf: true,
        at: DateTime.now(),
      ));
      notifyListeners();
      _channel?.sink.add(msgCipherFrame(ciphertext: encrypted.ciphertext, nonce: encrypted.nonce));
    }
  }

  /// @visibleForTesting — exposes the raw key bytes so tests can verify zeroing.
  @visibleForTesting
  Uint8List? get debugKeyBytes => _key;

  Future<void> close() async {
    final channel = _channel;
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    _pendingDecrypt.clear();
    _roomCode = null;
    _lastError = null;
    _passwordMode = false;
    _isHost = null;
    _localNickname = null;
    // Strings are immutable; clearing the list drops references but does not zero memory.
    _messages.clear();
    zeroBytes(_key);
    _key = null;
    _mismatchDetected = false;
    _state = ChatConnectionState.idle;
    try {
      await Future.any([
        channel?.sink.close() ?? Future.value(),
        Future.delayed(const Duration(seconds: 1)),
      ]);
    } catch (_) {}
    notifyListeners();
  }
}
