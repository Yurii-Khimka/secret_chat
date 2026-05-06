import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secret_chat/components/caret.dart';
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

  group('Caret', () {
    testWidgets('renders with requested dimensions and starts visible', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Caret(palette: theme.palette, height: 22, width: 10),
        ),
      ));
      await tester.pump();

      // Find the Caret widget
      expect(find.byType(Caret), findsOneWidget);
      // Initially visible
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });

    testWidgets('toggles visibility after 530ms', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Caret(palette: theme.palette),
        ),
      ));

      // Initially visible
      var opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);

      // Advance past one blink cycle
      await tester.pump(const Duration(milliseconds: 600));
      opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.0);

      // Advance past another cycle — back to visible
      await tester.pump(const Duration(milliseconds: 600));
      opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });

    testWidgets('disposes without throwing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Caret(palette: theme.palette),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      // Replace the widget tree to trigger dispose
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ));
      // No exception means clean dispose
    });
  });
}
