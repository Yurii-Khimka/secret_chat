import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secret_chat/main.dart';
import 'package:secret_chat/theme/theme_controller.dart';
import 'package:secret_chat/network/chat_client.dart';

void main() {
  testWidgets('App builds HomeScreen without errors', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();
    await controller.load();

    await tester.pumpWidget(SecretChatApp(controller: controller, chatClient: ChatClient()));
    await tester.pump();
    expect(find.textContaining('SECRET'), findsOneWidget);
  });
}
