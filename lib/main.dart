import 'package:flutter/material.dart';
import 'theme/theme_controller.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_name.dart';
import 'tokens/tokens.dart';

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
          home: _ThemeSmokeScreen(
            theme: theme,
            controller: _themeController,
          ),
        );
      },
    );
  }
}

/// Temporary smoke-test screen — will be deleted in Task 3.
class _ThemeSmokeScreen extends StatelessWidget {
  const _ThemeSmokeScreen({
    required this.theme,
    required this.controller,
  });

  final AppTheme theme;
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final palette = theme.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active theme: ${theme.name.name}',
                style: AppTypography.body.copyWith(color: palette.accent),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Theme selector
              Wrap(
                spacing: AppSpacing.sm,
                children: AppThemeName.values.map((name) {
                  final isActive = name == controller.current;
                  return GestureDetector(
                    onTap: () => controller.setTheme(name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? palette.accent : palette.surface,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: isActive
                              ? palette.accent
                              : palette.borderHighlight,
                        ),
                      ),
                      child: Text(
                        name.name,
                        style: AppTypography.caption.copyWith(
                          color:
                              isActive ? palette.accentText : palette.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                '// PALETTE SLOTS',
                style: AppTypography.caption.copyWith(color: palette.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              // Palette swatches
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _buildSwatches(palette),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSwatches(AppPalette palette) {
    final slots = <String, Color>{
      'background': palette.background,
      'surface': palette.surface,
      'surfaceMuted': palette.surfaceMuted,
      'border': palette.border,
      'borderHighlight': palette.borderHighlight,
      'textPrimary': palette.textPrimary,
      'textSecondary': palette.textSecondary,
      'textMuted': palette.textMuted,
      'accent': palette.accent,
      'accentMuted': palette.accentMuted,
      'accentText': palette.accentText,
      'accentGhost': palette.accentGhost,
      'accentGlow': palette.accentGlow,
      'bubbleSent': palette.bubbleSent,
      'bubbleSentText': palette.bubbleSentText,
      'bubbleReceived': palette.bubbleReceived,
      'bubbleReceivedText': palette.bubbleReceivedText,
      'warning': palette.warning,
    };

    return slots.entries.map((entry) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: entry.value,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: palette.borderHighlight),
        ),
        alignment: Alignment.center,
        child: Text(
          entry.key,
          style: AppTypography.micro.copyWith(
            color: palette.textPrimary,
            letterSpacing: 0,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }).toList();
  }
}
