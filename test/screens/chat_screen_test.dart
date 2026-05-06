import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  group('mismatchDetected UI', () {
    testWidgets('composer disabled when mismatchDetected', (tester) async {
      final client = _FakeChatClient(mismatchDetected: true);

      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      // TextField should be disabled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    testWidgets('hint text shows mismatch message', (tester) async {
      final client = _FakeChatClient(mismatchDetected: true);

      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(find.text('phrase mismatch \u2014 leave the room'), findsOneWidget);
    });

    testWidgets('mismatch system message is shown', (tester) async {
      final client = _FakeChatClient(mismatchDetected: true);

      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(
        find.textContaining('the phrase you typed does not match'),
        findsOneWidget,
      );
    });

    testWidgets('tap anywhere calls close on mismatch', (tester) async {
      final client = _FakeChatClient(mismatchDetected: true);

      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      // Tap the body area (GestureDetector wrapping the Column)
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(client.closeCalled, true);
    });

    testWidgets('ENCRYPTED label shown in password mode', (tester) async {
      final client = _FakeChatClient(passwordMode: true);

      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(find.text('ENCRYPTED'), findsWidgets);
    });

    testWidgets('PLAINTEXT label shown in open mode', (tester) async {
      final client = _FakeChatClient(passwordMode: false);

      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(find.text('PLAINTEXT'), findsWidgets);
    });

    testWidgets('decryptFailed bubble shows unreadable italic', (tester) async {
      final client = _FakeChatClient(
        passwordMode: true,
        messages: [
          ChatMessage(text: '', fromSelf: false, at: DateTime.now(), decryptFailed: true),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(find.text('unreadable'), findsOneWidget);
    });
  });
}

class _FakeChatClient extends ChangeNotifier implements ChatClient {
  _FakeChatClient({
    bool mismatchDetected = false,
    bool passwordMode = true,
    List<ChatMessage>? messages,
  })  : _mismatchDetected = mismatchDetected,
        _passwordMode = passwordMode,
        _messages = messages ?? [];

  final bool _mismatchDetected;
  final bool _passwordMode;
  final List<ChatMessage> _messages;
  bool closeCalled = false;

  @override
  bool get mismatchDetected => _mismatchDetected;
  @override
  bool get passwordMode => _passwordMode;
  @override
  bool get hasKey => true;
  @override
  bool? get isHost => true;
  @override
  String? get localNickname => null;
  @override
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  @override
  ChatConnectionState get state => ChatConnectionState.paired;
  @override
  String? get roomCode => 'TEST-1234';
  @override
  String? get lastError => null;
  @override
  Uint8List? get debugKeyBytes => null;

  @override
  Future<void> createRoom({bool passwordMode = false, String? nickname}) async {}
  @override
  Future<void> joinRoom(String code, {String? nickname}) async {}
  @override
  Future<void> sendMessage(String text) async {}
  @override
  Future<void> close() async {
    closeCalled = true;
    notifyListeners();
  }
}
