import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secret_chat/components/system_message.dart';
import 'package:secret_chat/network/chat_client.dart';
import 'package:secret_chat/screens/chat_screen.dart';
import 'package:secret_chat/theme/app_theme.dart';
import 'package:secret_chat/theme/theme_controller.dart';
void main() {
  late AppTheme theme;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();
    await controller.load();
    theme = AppTheme.forName(controller.current);
  });

  group('SystemMessage alignment', () {
    testWidgets('single-line text is centered', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SystemMessage(
            text: 'code copied',
            palette: theme.palette,
          ),
        ),
      ));

      final center = find.byType(Center);
      expect(center, findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('code copied'));
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('multi-line text is left-aligned (no Center)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SystemMessage(
            text: 'line one\nline two\nline three',
            palette: theme.palette,
          ),
        ),
      ));

      final center = find.byType(Center);
      expect(center, findsNothing);

      final textWidget = tester.widget<Text>(find.textContaining('line one'));
      expect(textWidget.textAlign, TextAlign.start);
    });
  });

  group('ChatClient isHost + localNickname', () {
    test('createRoom sets isHost=true and localNickname', () async {
      final client = ChatClient();
      // We can't fully connect in tests, but we can verify state is set
      // before the connect call by inspecting after the error state
      await client.createRoom(nickname: 'alice');
      expect(client.isHost, true);
      expect(client.localNickname, 'alice');
      await client.close();
    });

    test('joinRoom trims nickname and sets isHost=false', () async {
      final client = ChatClient();
      await client.joinRoom('WOLF-1234', nickname: '  bob  ');
      expect(client.isHost, false);
      expect(client.localNickname, 'bob');
      await client.close();
    });

    test('joinRoom with blank nickname sets localNickname=null', () async {
      final client = ChatClient();
      await client.joinRoom('WOLF-1234', nickname: '   ');
      expect(client.isHost, false);
      expect(client.localNickname, null);
      await client.close();
    });

    test('close resets isHost and localNickname to null', () async {
      final client = ChatClient();
      await client.createRoom(nickname: 'alice');
      await client.close();
      expect(client.isHost, null);
      expect(client.localNickname, null);
    });
  });

  group('ChatScreen labels', () {
    testWidgets('isHost=true, no nickname: self=host, peer=peer', (tester) async {
      final client = _FakeChatClient(
        isHost: true,
        localNickname: null,
        messages: [
          ChatMessage(text: 'hello', fromSelf: true, at: DateTime.now()),
          ChatMessage(text: 'hi', fromSelf: false, at: DateTime.now()),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(find.text('host'), findsOneWidget);
      expect(find.text('peer'), findsWidgets); // label + disconnect text may contain 'peer'
      expect(find.text('YOU'), findsNothing);
    });

    testWidgets('isHost=false, nickname=alice: self=alice, peer=host', (tester) async {
      final client = _FakeChatClient(
        isHost: false,
        localNickname: 'alice',
        messages: [
          ChatMessage(text: 'hello', fromSelf: true, at: DateTime.now()),
          ChatMessage(text: 'hi', fromSelf: false, at: DateTime.now()),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(find.text('alice'), findsOneWidget);
      expect(find.text('host'), findsOneWidget);
      expect(find.text('YOU'), findsNothing);
    });

    testWidgets('YOU is never rendered', (tester) async {
      final client = _FakeChatClient(
        isHost: true,
        localNickname: null,
        messages: [
          ChatMessage(text: 'test', fromSelf: true, at: DateTime.now()),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(find.text('YOU'), findsNothing);
    });
  });
}

/// Fake ChatClient that exposes preset state without connecting.
class _FakeChatClient extends ChangeNotifier implements ChatClient {
  _FakeChatClient({
    required bool? isHost,
    required String? localNickname,
    required List<ChatMessage> messages,
  })  : _isHost = isHost,
        _localNickname = localNickname,
        _messages = messages;

  final bool? _isHost;
  final String? _localNickname;
  final List<ChatMessage> _messages;

  @override
  bool? get isHost => _isHost;
  @override
  String? get localNickname => _localNickname;
  @override
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  @override
  ChatConnectionState get state => ChatConnectionState.paired;
  @override
  String? get roomCode => 'TEST-1234';
  @override
  String? get lastError => null;
  @override
  bool get passwordMode => false;
  @override
  bool get hasKey => false;

  @override
  Future<void> createRoom({bool passwordMode = false, String? nickname}) async {}
  @override
  Future<void> joinRoom(String code, {String? nickname}) async {}
  @override
  Future<void> sendMessage(String text) async {}
  @override
  Future<void> close() async {}
}
