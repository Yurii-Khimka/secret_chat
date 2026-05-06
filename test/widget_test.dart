import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secret_chat/main.dart';
import 'package:secret_chat/theme/theme_controller.dart';
import 'package:secret_chat/network/chat_client.dart';
import 'package:secret_chat/security/activation_controller.dart';
import 'package:secret_chat/security/activation.dart';

import 'helpers/activation_helpers.dart';

void main() {
  tearDown(() => setActivationPublicKeyForTesting(null));

  testWidgets('App builds HomeScreen without errors', (WidgetTester tester) async {
    final validCode = await generateTestActivationCode();
    SharedPreferences.setMockInitialValues({'activation.code': validCode});
    final controller = ThemeController();
    await controller.load();
    final activation = ActivationController();
    await activation.load();

    await tester.pumpWidget(SecretChatApp(
      controller: controller,
      chatClient: ChatClient(),
      activationController: activation,
    ));
    await tester.pump();
    expect(find.textContaining('SECRET'), findsOneWidget);
  });
}
