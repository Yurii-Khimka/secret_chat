import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secret_chat/theme/app_theme.dart';
import 'package:secret_chat/theme/theme_controller.dart';
import 'package:secret_chat/network/chat_client.dart';
import 'package:secret_chat/screens/room_setup_screen.dart';
import 'package:secret_chat/screens/join_room_screen.dart';
import 'package:secret_chat/screens/chat_screen.dart';
import 'package:secret_chat/components/app_toggle.dart';

void main() {
  late AppTheme theme;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();
    await controller.load();
    theme = AppTheme.forName(controller.current);
  });

  group('RoomSetupScreen', () {
    testWidgets('State 1: shows nickname input, password toggle, and Generate Code', (tester) async {
      final client = ChatClient();
      await tester.pumpWidget(MaterialApp(
        home: RoomSetupScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(find.text('ROOM SETUP'), findsOneWidget);
      expect(find.text('----'), findsOneWidget);
      expect(find.text('PASSWORD MODE'), findsOneWidget);
      expect(find.text('GENERATE CODE'), findsOneWidget);
      expect(find.byType(AppToggle), findsOneWidget);
    });

    testWidgets('password toggle shows helper text when ON', (tester) async {
      final client = ChatClient();
      await tester.pumpWidget(MaterialApp(
        home: RoomSetupScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      // Toggle is off — helper text not shown
      expect(find.textContaining('shared phrase'), findsNothing);

      // Tap the toggle
      await tester.tap(find.byType(AppToggle));
      await tester.pump();

      // Now helper text appears
      expect(find.textContaining('shared phrase'), findsOneWidget);
    });
  });

  group('JoinRoomScreen', () {
    testWidgets('does not have a PASSWORD field', (tester) async {
      final client = ChatClient();
      await tester.pumpWidget(MaterialApp(
        home: JoinRoomScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(find.text('// PASSWORD (OPTIONAL)'), findsNothing);
      expect(find.text('SHA-256 ▸ AES-256'), findsNothing);
      expect(find.textContaining('password mode is set by the room creator'), findsOneWidget);
    });
  });

  group('ChatScreen', () {
    testWidgets('passwordMode false shows plaintext warning', (tester) async {
      final client = _FakeChatClient(passwordMode: false);
      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(find.text('[plaintext — encryption arrives in task 9]'), findsOneWidget);
    });

    testWidgets('passwordMode true shows phrase-mode system message', (tester) async {
      final client = _FakeChatClient(passwordMode: true);
      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(theme: theme, chatClient: client),
      ));
      await tester.pump();

      expect(find.textContaining('phrase mode'), findsOneWidget);
      expect(find.textContaining('shared phrase'), findsOneWidget);
      expect(find.text('[plaintext — encryption arrives in task 9]'), findsNothing);
    });
  });
}

class _FakeChatClient extends ChatClient {
  _FakeChatClient({required bool passwordMode}) {
    _fakePasswordMode = passwordMode;
  }
  late bool _fakePasswordMode;

  @override
  bool get passwordMode => _fakePasswordMode;

  @override
  ChatConnectionState get state => ChatConnectionState.paired;

  @override
  String? get roomCode => 'TEST-0000';

  @override
  List<IncomingMessage> get messages => [];
}
