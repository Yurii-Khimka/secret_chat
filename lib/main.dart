import 'package:flutter/material.dart';
import 'theme/theme_controller.dart';
import 'screens/home_screen.dart';

final _themeController = ThemeController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _themeController.load();
  runApp(const SecretChatApp());
}

class SecretChatApp extends StatelessWidget {
  const SecretChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        final theme = _themeController.theme;
        return MaterialApp(
          title: 'Secret Chat',
          debugShowCheckedModeBanner: false,
          home: HomeScreen(theme: theme),
        );
      },
    );
  }
}
