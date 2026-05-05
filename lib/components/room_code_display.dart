import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

class RoomCodeDisplay extends StatelessWidget {
  const RoomCodeDisplay({
    super.key,
    required this.code,
    required this.palette,
    this.onCopy,
  });

  final String code;
  final AppPalette palette;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    // Split code at dash: "WOLF-7342" → "WOLF" + "7342"
    final parts = code.split('-');
    final prefix = parts.isNotEmpty ? parts[0] : code;
    final suffix = parts.length > 1 ? parts[1] : '';

    return GestureDetector(
      onTap: onCopy,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl - 2,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: palette.borderHighlight),
          borderRadius: BorderRadius.circular(AppRadii.md),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.surfaceMuted, palette.surface],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  prefix,
                  style: AppTypography.heading.copyWith(
                    color: palette.accent,
                    fontSize: 38,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6.84,
                    shadows: [
                      Shadow(
                        color: palette.accentGlow,
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                Text(
                  '—',
                  style: AppTypography.heading.copyWith(
                    color: palette.textMuted,
                    fontSize: 38,
                  ),
                ),
                Text(
                  suffix,
                  style: AppTypography.heading.copyWith(
                    color: palette.accent,
                    fontSize: 38,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6.84,
                    shadows: [
                      Shadow(
                        color: palette.accentGlow,
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onCopy != null) ...[
              const SizedBox(height: AppSpacing.sm + 2),
              Text(
                'TAP TO COPY',
                style: AppTypography.micro.copyWith(color: palette.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
