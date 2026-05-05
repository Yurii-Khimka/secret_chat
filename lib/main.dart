import 'package:flutter/material.dart';
import 'theme/theme_controller.dart';
import 'network/chat_client.dart';
import 'screens/home_screen.dart';

final themeController = ThemeController();
final chatClient = ChatClient();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  runApp(SecretChatApp(controller: themeController, chatClient: chatClient));
}

class SecretChatApp extends StatefulWidget {
  const SecretChatApp({super.key, required this.controller, required this.chatClient});

  final ThemeController controller;
  final ChatClient chatClient;

  @override
  State<SecretChatApp> createState() => _SecretChatAppState();
}

class _SecretChatAppState extends State<SecretChatApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      widget.chatClient.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final theme = widget.controller.theme;
        return MaterialApp(
          title: 'Secret Chat',
          debugShowCheckedModeBanner: false,
          home: HomeScreen(theme: theme, controller: widget.controller, chatClient: widget.chatClient),
        );
      },
    );
  }
}
