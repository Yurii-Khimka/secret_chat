import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secret_chat/main.dart';
import 'package:secret_chat/theme/theme_controller.dart';
import 'package:secret_chat/theme/app_theme_name.dart';
import 'package:secret_chat/theme/palettes/lime_palette.dart';
import 'package:secret_chat/theme/palettes/mint_palette.dart';
import 'package:secret_chat/theme/palettes/indigo_palette.dart';

void main() {
  group('Theme persistence', () {
    testWidgets('cold start loads Lime when persisted', (tester) async {
      SharedPreferences.setMockInitialValues({'app.theme': 'lime'});
      final controller = ThemeController();
      await controller.load();

      expect(controller.theme.palette.accent, equals(limePalette.accent));
    });

    testWidgets('cold start falls back to Mint when empty', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = ThemeController();
      await controller.load();

      expect(controller.theme.palette.accent, equals(mintPalette.accent));
    });

    testWidgets('tapping Indigo in Settings persists choice', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = ThemeController();
      await controller.load();

      await tester.pumpWidget(SecretChatApp(controller: controller));
      await tester.pump();

      // Navigate to Settings
      await tester.tap(find.text('⚙ SETTINGS'));
      await tester.pumpAndSettle();

      // Tap INDIGO row
      await tester.tap(find.text('INDIGO'));
      await tester.pump();

      // Assert active theme is Indigo
      expect(controller.current, equals(AppThemeName.indigo));
      expect(controller.theme.palette.accent, equals(indigoPalette.accent));

      // Assert persisted value
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app.theme'), equals('indigo'));
    });
  });
}
