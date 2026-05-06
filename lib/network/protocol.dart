import 'dart:convert';

// Wire protocol constants — must match server/src/protocol.js exactly.
const kHello = 'hello';
const kCreateRoom = 'create_room';
const kRoomCreated = 'room_created';
const kJoinRoom = 'join_room';
const kJoined = 'joined';
const kPeerJoined = 'peer_joined';
const kPeerLeft = 'peer_left';
const kMsg = 'msg';
const kError = 'error';

final kCodeRegex = RegExp(r'^[A-Z]{3,5}-\d{4}$');

// ── Inbound (server → client) ──────────────────────────────────

sealed class ServerMessage {}

class HelloMsg extends ServerMessage {
  HelloMsg(this.v);
  final String v;
}

class RoomCreatedMsg extends ServerMessage {
  RoomCreatedMsg(this.code, this.passwordMode);
  final String code;
  final bool passwordMode;
}

class JoinedMsg extends ServerMessage {
  JoinedMsg(this.code, this.passwordMode);
  final String code;
  final bool passwordMode;
}

class PeerJoinedMsg extends ServerMessage {}

class PeerLeftMsg extends ServerMessage {}

class MsgMsg extends ServerMessage {
  MsgMsg({this.text, this.ciphertext, this.nonce});
  final String? text;
  final String? ciphertext;
  final String? nonce;
}

class ErrorMsg extends ServerMessage {
  ErrorMsg(this.code, this.reason);
  final String code;
  final String reason;
}

ServerMessage? parseFrame(String raw) {
  final Map<String, dynamic> parsed;
  try {
    parsed = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }

  final type = parsed['type'];
  if (type is! String) return null;

  return switch (type) {
    kHello => HelloMsg(parsed['v'] as String? ?? ''),
    kRoomCreated => parsed['code'] is String
        ? RoomCreatedMsg(parsed['code'] as String, parsed['password_mode'] as bool? ?? false)
        : null,
    kJoined => parsed['code'] is String
        ? JoinedMsg(parsed['code'] as String, parsed['password_mode'] as bool? ?? false)
        : null,
    kPeerJoined => PeerJoinedMsg(),
    kPeerLeft => PeerLeftMsg(),
    kMsg => _parseMsgMsg(parsed),
    kError => ErrorMsg(
        parsed['code'] as String? ?? 'unknown',
        parsed['reason'] as String? ?? '',
      ),
    _ => null,
  };
}

MsgMsg? _parseMsgMsg(Map<String, dynamic> parsed) {
  final text = parsed['text'];
  final ciphertext = parsed['ciphertext'];
  final nonce = parsed['nonce'];

  if (text is String && text.isNotEmpty && ciphertext == null && nonce == null) {
    return MsgMsg(text: text);
  }
  if (ciphertext is String && ciphertext.isNotEmpty && nonce is String && nonce.isNotEmpty && text == null) {
    return MsgMsg(ciphertext: ciphertext, nonce: nonce);
  }
  return null;
}

// ── Outbound (client → server) ─────────────────────────────────

String createRoomFrame({bool passwordMode = false}) =>
    jsonEncode({'type': kCreateRoom, 'password_mode': passwordMode});

String joinRoomFrame(String code) => jsonEncode({'type': kJoinRoom, 'code': code});

String msgTextFrame(String text) => jsonEncode({'type': kMsg, 'text': text});

String msgCipherFrame({required String ciphertext, required String nonce}) =>
    jsonEncode({'type': kMsg, 'ciphertext': ciphertext, 'nonce': nonce});
