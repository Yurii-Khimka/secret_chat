import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

/// Centered system/status message used in the chat screen
/// (screens.jsx — "— session opened —", "peer joined · key verified ✓").
class SystemMessage extends StatelessWidget {
  const SystemMessage({
    super.key,
    required this.text,
    required this.palette,
  });

  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 2),
        child: Text(
          text,
          style: AppTypography.micro.copyWith(color: palette.textMuted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
