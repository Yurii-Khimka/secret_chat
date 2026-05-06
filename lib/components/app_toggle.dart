import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.palette,
    this.onChanged,
  });

  final bool value;
  final AppPalette palette;
  final ValueChanged<bool>? onChanged;

  bool get _enabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final trackColor = value ? palette.accent : palette.border;
    final thumbColor = value ? palette.accentText : palette.textMuted;

    return GestureDetector(
      onTap: _enabled ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? palette.accent : palette.borderHighlight,
          ),
        ),
        child: AnimatedAlign(
          duration: AppDurations.fast,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: thumbColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
