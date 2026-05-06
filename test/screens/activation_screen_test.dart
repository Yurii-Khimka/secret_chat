import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secret_chat/security/activation.dart';
import 'package:secret_chat/security/activation_controller.dart';
import 'package:secret_chat/screens/activation_screen.dart';
import 'package:secret_chat/theme/app_theme.dart';
import 'package:secret_chat/theme/app_theme_name.dart';

import '../helpers/activation_helpers.dart';

void main() {
  late ActivationController controller;
  final theme = AppTheme.forName(AppThemeName.defaultTheme);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = ActivationController();
  });

  tearDown(() => setActivationPublicKeyForTesting(null));

  Widget buildApp() {
    return MaterialApp(
      home: ActivationScreen(theme: theme, controller: controller),
    );
  }

  group('ActivationScreen', () {
    testWidgets('ACTIVATE button is disabled with empty input', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('ACTIVATE'), findsOneWidget);
    });

    testWidgets('typing enables button, valid code activates', (tester) async {
      final validCode = await tester.runAsync(() => generateTestActivationCode());
      await tester.pumpWidget(buildApp());
      await tester.pump();

      await tester.enterText(find.byType(TextField), validCode!);
      await tester.pump();

      await tester.tap(find.text('ACTIVATE'));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();

      expect(controller.activated, isTrue);
    });

    testWidgets('invalid code shows error text', (tester) async {
      setActivationPublicKeyForTesting(List<int>.filled(32, 1));
      await tester.pumpWidget(buildApp());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'invalid.code');
      await tester.pump();

      await tester.tap(find.text('ACTIVATE'));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();

      expect(find.text('[ERROR] code not valid'), findsOneWidget);
    });

    testWidgets('editing field after error clears error text', (tester) async {
      setActivationPublicKeyForTesting(List<int>.filled(32, 1));
      await tester.pumpWidget(buildApp());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'invalid.code');
      await tester.pump();

      await tester.tap(find.text('ACTIVATE'));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();

      expect(find.text('[ERROR] code not valid'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'something else');
      await tester.pump();

      expect(find.text('[ERROR] code not valid'), findsNothing);
    });
  });
}
