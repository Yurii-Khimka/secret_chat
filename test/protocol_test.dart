import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_chat/network/protocol.dart';

void main() {
  group('parseFrame', () {
    test('parses hello', () {
      final msg = parseFrame('{"type":"hello","v":"0.1.0"}');
      expect(msg, isA<HelloMsg>());
      expect((msg as HelloMsg).v, '0.1.0');
    });

    test('parses room_created', () {
      final msg = parseFrame('{"type":"room_created","code":"WOLF-1234"}');
      expect(msg, isA<RoomCreatedMsg>());
      final rc = msg as RoomCreatedMsg;
      expect(rc.code, 'WOLF-1234');
      expect(rc.passwordMode, false);
    });

    test('parses room_created with password_mode true', () {
      final msg = parseFrame('{"type":"room_created","code":"WOLF-1234","password_mode":true}');
      expect(msg, isA<RoomCreatedMsg>());
      expect((msg as RoomCreatedMsg).passwordMode, true);
    });

    test('parses joined', () {
      final msg = parseFrame('{"type":"joined","code":"BEAR-5678"}');
      expect(msg, isA<JoinedMsg>());
      final j = msg as JoinedMsg;
      expect(j.code, 'BEAR-5678');
      expect(j.passwordMode, false);
    });

    test('parses joined with password_mode true', () {
      final msg = parseFrame('{"type":"joined","code":"BEAR-5678","password_mode":true}');
      expect(msg, isA<JoinedMsg>());
      expect((msg as JoinedMsg).passwordMode, true);
    });

    test('parses peer_joined', () {
      final msg = parseFrame('{"type":"peer_joined"}');
      expect(msg, isA<PeerJoinedMsg>());
    });

    test('parses peer_left', () {
      final msg = parseFrame('{"type":"peer_left"}');
      expect(msg, isA<PeerLeftMsg>());
    });

    test('parses msg with special chars', () {
      final payload = 'a"b\\cé';
      final raw = jsonEncode({'type': 'msg', 'payload': payload});
      final msg = parseFrame(raw);
      expect(msg, isA<MsgMsg>());
      expect((msg as MsgMsg).payload, payload);
    });

    test('parses error', () {
      final msg = parseFrame('{"type":"error","code":"not_found","reason":"room does not exist"}');
      expect(msg, isA<ErrorMsg>());
      final err = msg as ErrorMsg;
      expect(err.code, 'not_found');
      expect(err.reason, 'room does not exist');
    });

    test('returns null for malformed JSON', () {
      expect(parseFrame('not json'), isNull);
    });

    test('returns null for unknown type', () {
      expect(parseFrame('{"type":"foo"}'), isNull);
    });

    test('returns null for missing fields', () {
      // room_created without code
      expect(parseFrame('{"type":"room_created"}'), isNull);
      // msg without payload
      expect(parseFrame('{"type":"msg"}'), isNull);
    });
  });

  group('outbound builders', () {
    test('createRoomFrame default', () {
      final parsed = jsonDecode(createRoomFrame());
      expect(parsed['type'], 'create_room');
      expect(parsed['password_mode'], false);
    });

    test('createRoomFrame with passwordMode true', () {
      final parsed = jsonDecode(createRoomFrame(passwordMode: true));
      expect(parsed['type'], 'create_room');
      expect(parsed['password_mode'], true);
    });

    test('joinRoomFrame', () {
      final parsed = jsonDecode(joinRoomFrame('HAWK-9999'));
      expect(parsed['type'], 'join_room');
      expect(parsed['code'], 'HAWK-9999');
    });

    test('msgFrame', () {
      final parsed = jsonDecode(msgFrame('hello world'));
      expect(parsed['type'], 'msg');
      expect(parsed['payload'], 'hello world');
    });
  });

  group('kCodeRegex', () {
    test('matches valid codes', () {
      expect(kCodeRegex.hasMatch('WOLF-1234'), isTrue);
      expect(kCodeRegex.hasMatch('BEAR-0000'), isTrue);
      expect(kCodeRegex.hasMatch('HAWKS-9999'), isTrue);
    });

    test('rejects invalid codes', () {
      expect(kCodeRegex.hasMatch('wolf-1234'), isFalse);
      expect(kCodeRegex.hasMatch('WO-1234'), isFalse);
      expect(kCodeRegex.hasMatch('WOLF-123'), isFalse);
      expect(kCodeRegex.hasMatch('WOLF-12345'), isFalse);
    });
  });
}
