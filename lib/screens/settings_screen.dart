import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../tokens/tokens.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_name.dart';
import '../theme/theme_controller.dart';
import '../components/app_scaffold.dart';
import '../dev/component_gallery_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.theme,
    required this.controller,
  });

  final AppTheme theme;
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final p = theme.palette;

    // Accent color per theme name (for the swatch preview)
    final accentForTheme = <AppThemeName, Color>{
      for (final name in AppThemeName.values)
        name: AppTheme.forName(name).palette.accent,
    };

    return AppScaffold(
      palette: p,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TermHeader (inline) ─────────────────────
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Text(
                        '‹',
                        style: AppTypography.heading.copyWith(
                          color: p.textMuted,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'SETTINGS',
                    style: AppTypography.caption.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),

            // ── Body ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Theme section ────────────────────
                    Text(
                      '// THEME',
                      style: AppTypography.caption.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...AppThemeName.values.map((name) {
                      final isActive = name == controller.current;
                      return _ThemeRow(
                        name: name,
                        accentColor: accentForTheme[name]!,
                        isActive: isActive,
                        palette: p,
                        onTap: () => controller.setTheme(name),
                      );
                    }),

                    // ── Developer section (debug only) ──  // line 82
                    if (kDebugMode) ...[
                      const SizedBox(height: AppSpacing.xxxl),
                      Text(
                        '// DEVELOPER',
                        style: AppTypography.caption.copyWith(color: p.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ComponentGalleryScreen(
                                theme: theme,
                                controller: controller,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: p.surface,
                            border: Border.all(color: p.border),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'COMPONENT GALLERY',
                                style: AppTypography.mono.copyWith(color: p.textPrimary),
                              ),
                              Text(
                                '→',
                                style: AppTypography.body.copyWith(color: p.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.name,
    required this.accentColor,
    required this.isActive,
    required this.palette,
    required this.onTap,
  });

  final AppThemeName name;
  final Color accentColor;
  final bool isActive;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive ? palette.accentGhost : palette.surface,
          border: Border.all(
            color: isActive ? palette.borderHighlight : palette.border,
          ),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            // Accent swatch
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Theme name
            Expanded(
              child: Text(
                name.name.toUpperCase(),
                style: AppTypography.mono.copyWith(
                  color: isActive ? palette.accent : palette.textPrimary,
                ),
              ),
            ),
            // Active marker
            if (isActive)
              Text(
                '›',
                style: AppTypography.body.copyWith(color: palette.accent),
              ),
          ],
        ),
      ),
    );
  }
}
