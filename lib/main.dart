import 'package:flutter/material.dart';
import 'theme/theme_controller.dart';
import 'network/chat_client.dart';
import 'security/activation_controller.dart';
import 'screens/home_screen.dart';
import 'screens/activation_screen.dart';

bool shouldCloseOnLifecycle(AppLifecycleState state) =>
    state == AppLifecycleState.detached;

final themeController = ThemeController();
final chatClient = ChatClient();
final activationController = ActivationController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  await activationController.load();
  runApp(SecretChatApp(
    controller: themeController,
    chatClient: chatClient,
    activationController: activationController,
  ));
}

class SecretChatApp extends StatefulWidget {
  const SecretChatApp({
    super.key,
    required this.controller,
    required this.chatClient,
    required this.activationController,
  });

  final ThemeController controller;
  final ChatClient chatClient;
  final ActivationController activationController;

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
    // Lifecycle policy:
    //   paused / inactive / hidden  →  no-op (routine backgrounding preserves the session)
    //   detached                    →  close (process going away — wipe everything)
    if (shouldCloseOnLifecycle(state)) {
      widget.chatClient.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, widget.activationController]),
      builder: (context, _) {
        final theme = widget.controller.theme;
        return MaterialApp(
          title: 'Secret Chat',
          debugShowCheckedModeBanner: false,
          home: widget.activationController.activated
              ? HomeScreen(theme: theme, controller: widget.controller, chatClient: widget.chatClient)
              : ActivationScreen(theme: theme, controller: widget.activationController),
        );
      },
    );
  }
}
