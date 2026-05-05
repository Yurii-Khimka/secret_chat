import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secret_chat/main.dart';
import 'package:secret_chat/theme/theme_controller.dart';

void main() {
  testWidgets('App builds HomeScreen without errors', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();
    await controller.load();

    await tester.pumpWidget(SecretChatApp(controller: controller));
    await tester.pump();
    expect(find.textContaining('SECRET'), findsOneWidget);
  });
}
