import 'package:flutter/material.dart';
import 'theme/theme_controller.dart';
import 'screens/home_screen.dart';

final themeController = ThemeController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  runApp(SecretChatApp(controller: themeController));
}

class SecretChatApp extends StatelessWidget {
  const SecretChatApp({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = controller.theme;
        return MaterialApp(
          title: 'Secret Chat',
          debugShowCheckedModeBanner: false,
          home: HomeScreen(theme: theme, controller: controller),
        );
      },
    );
  }
}
