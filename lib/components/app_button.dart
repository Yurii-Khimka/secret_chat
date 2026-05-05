import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

enum AppButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.palette,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.enabled = true,
    this.expand = false,
    this.sub,
  });

  final String label;
  final AppPalette palette;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool enabled;
  final bool expand;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppButtonVariant.primary;
    final isDisabled = !enabled || onPressed == null;

    final Color bg;
    final Color fg;
    final Color borderColor;
    final List<BoxShadow> shadows;

    if (isDisabled) {
      bg = isPrimary ? palette.accentMuted : palette.surface;
      fg = isPrimary ? palette.accentText.withValues(alpha: 0.5) : palette.textMuted;
      borderColor = isPrimary ? palette.accentMuted : palette.border;
      shadows = const [];
    } else if (isPrimary) {
      bg = palette.accent;
      fg = palette.accentText;
      borderColor = palette.accent;
      shadows = [
        BoxShadow(
          color: palette.accentGlow,
          blurRadius: 24,
          offset: const Offset(0, 6),
          spreadRadius: -8,
        ),
      ];
    } else {
      bg = palette.surfaceMuted;
      fg = palette.textPrimary;
      borderColor = palette.borderHighlight;
      shadows = const [];
    }

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Container(
        width: expand ? double.infinity : null,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: shadows,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.button.copyWith(color: fg),
                ),
                Text(
                  isPrimary ? '↵' : '→',
                  style: AppTypography.body.copyWith(
                    color: fg.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            if (sub != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                sub!,
                style: AppTypography.caption.copyWith(
                  color: isPrimary
                      ? palette.accentText.withValues(alpha: 0.67)
                      : palette.textSecondary,
                  letterSpacing: 0.14,
                  textBaseline: TextBaseline.alphabetic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
