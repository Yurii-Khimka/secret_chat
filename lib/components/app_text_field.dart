import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.label,
    this.obscure = false,
    this.monospace = true,
    this.autoFocus = false,
    this.onChanged,
    required this.palette,
    this.prefixChar,
    this.trailingText,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final String? label;
  final bool obscure;
  final bool monospace;
  final bool autoFocus;
  final ValueChanged<String>? onChanged;
  final AppPalette palette;
  final String? prefixChar;
  final String? trailingText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final textStyle = widget.monospace ? AppTypography.mono : AppTypography.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            '// ${widget.label!.toUpperCase()}',
            style: AppTypography.caption.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
        ],
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(
              color: _hasFocus ? p.borderHighlight : p.border,
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            children: [
              if (widget.prefixChar != null) ...[
                Text(
                  widget.prefixChar!,
                  style: textStyle.copyWith(color: p.textMuted),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: widget.autoFocus,
                  obscureText: widget.obscure,
                  onChanged: widget.onChanged,
                  style: textStyle.copyWith(color: p.textPrimary),
                  cursorColor: p.accent,
                  cursorWidth: 8,
                  cursorHeight: 14,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: widget.placeholder,
                    hintStyle: textStyle.copyWith(color: p.textMuted),
                  ),
                ),
              ),
              if (widget.trailingText != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.trailingText!,
                  style: AppTypography.micro.copyWith(color: p.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
