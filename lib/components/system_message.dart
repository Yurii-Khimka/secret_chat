import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

enum SystemMessageTone { muted, warning }

/// Centered system/status message used in the chat screen
/// (screens.jsx — "— session opened —", "peer joined · key verified ✓").
class SystemMessage extends StatelessWidget {
  const SystemMessage({
    super.key,
    required this.text,
    required this.palette,
    this.tone = SystemMessageTone.muted,
  });

  final String text;
  final AppPalette palette;
  final SystemMessageTone tone;

  bool get _isMultiline => text.contains('\n');

  @override
  Widget build(BuildContext context) {
    final color = tone == SystemMessageTone.warning
        ? palette.warning
        : palette.textMuted;

    if (_isMultiline) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm - 2,
          horizontal: AppSpacing.lg,
        ),
        child: Text(
          text,
          style: AppTypography.micro.copyWith(color: color),
          textAlign: TextAlign.start,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 2),
        child: Text(
          text,
          style: AppTypography.micro.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
