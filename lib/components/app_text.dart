import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

enum AppTextVariant { heading, body, mono, caption }

class AppText extends StatelessWidget {
  const AppText({
    super.key,
    required this.text,
    required this.palette,
    this.variant = AppTextVariant.body,
    this.color,
    this.align,
  });

  final String text;
  final AppPalette palette;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    final style = switch (variant) {
      AppTextVariant.heading => AppTypography.heading,
      AppTextVariant.body => AppTypography.body,
      AppTextVariant.mono => AppTypography.mono,
      AppTextVariant.caption => AppTypography.caption,
    };

    return Text(
      text,
      style: style.copyWith(color: color ?? palette.textPrimary),
      textAlign: align,
    );
  }
}
