import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/tokens.dart';
import '../theme/app_theme.dart';
import '../components/app_scaffold.dart';
import '../components/app_button.dart';
import '../components/app_text_field.dart';
import 'chat_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key, required this.theme});

  final AppTheme theme;

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  // 8 code slots: 4 prefix + 4 suffix
  final List<TextEditingController> _codeControllers =
      List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(8, (_) => FocusNode());

  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    _nicknameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _roomCode {
    final prefix = _codeControllers.sublist(0, 4).map((c) => c.text).join();
    final suffix = _codeControllers.sublist(4, 8).map((c) => c.text).join();
    return '${prefix.toUpperCase()}-${suffix.toUpperCase()}';
  }

  bool get _codeComplete {
    return _codeControllers.every((c) => c.text.isNotEmpty);
  }

  void _onCodeSlotChanged(int index, String value) {
    if (value.length > 1) {
      _codeControllers[index].text = value[value.length - 1];
      _codeControllers[index].selection = TextSelection.collapsed(offset: 1);
    }
    if (value.isNotEmpty && index < 7) {
      _codeFocusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  KeyEventResult _onCodeSlotKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _codeControllers[index].text.isEmpty &&
        index > 0) {
      _codeFocusNodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.theme.palette;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Text(
                            '‹ BACK',
                            style: AppTypography.caption.copyWith(color: p.textMuted),
                          ),
                        ),
                      ),
                      Text(
                        '  /  JOIN',
                        style: AppTypography.caption.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    'STEP 1 / 2',
                    style: AppTypography.caption.copyWith(color: p.textMuted),
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

                    // ── Room Code input ──────────────────
                    Text(
                      '// ROOM CODE',
                      style: AppTypography.caption.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.lg + 2),
                    Row(
                      children: [
                        ..._buildCodeSlots(0, 4, p),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          child: Text(
                            '—',
                            style: AppTypography.heading.copyWith(
                              color: p.textMuted,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        ..._buildCodeSlots(4, 8, p),
                      ],
                    ),

                    // ── Nickname ─────────────────────────
                    const SizedBox(height: AppSpacing.xl + 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '// NICKNAME (OPTIONAL)',
                          style: AppTypography.caption.copyWith(color: p.textMuted),
                        ),
                        Text(
                          'LOCAL ONLY',
                          style: AppTypography.micro.copyWith(color: p.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    AppTextField(
                      palette: p,
                      controller: _nicknameController,
                      placeholder: 'e.g. a.b. · knight · m',
                      prefixChar: '@',
                      trailingText: 'FALLBACK · PEER',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Shown to your peer instead of PEER.\nLeave blank to stay fully anonymous.',
                      style: AppTypography.caption.copyWith(
                        color: p.textSecondary,
                        letterSpacing: 0.14,
                      ),
                    ),

                    // ── Password ─────────────────────────
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '// PASSWORD (OPTIONAL)',
                          style: AppTypography.caption.copyWith(color: p.textMuted),
                        ),
                        Text(
                          'CASE-SENSITIVE',
                          style: AppTypography.micro.copyWith(color: p.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    AppTextField(
                      palette: p,
                      controller: _passwordController,
                      placeholder: 'type to derive a key',
                      obscure: true,
                      prefixChar: '\$',
                      trailingText: 'SHA-256 ▸ AES-256',
                    ),
                  ],
                ),
              ),
            ),

            // ── Connect button ──────────────────────────
            AppButton(
              label: 'Connect',
              palette: p,
              expand: true,
              enabled: _codeComplete,
              sub: 'Verifies the room and derives the shared key',
              onPressed: _codeComplete
                  ? () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            theme: widget.theme,
                            roomCode: _roomCode,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCodeSlots(int start, int end, AppPalette p) {
    return List.generate(end - start, (i) {
      final idx = start + i;
      final hasFill = _codeControllers[idx].text.isNotEmpty;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i < 3 ? AppSpacing.sm : 0),
          child: Focus(
            onKeyEvent: (_, event) => _onCodeSlotKey(idx, event),
            child: SizedBox(
              height: 56,
              child: TextField(
                controller: _codeControllers[idx],
                focusNode: _codeFocusNodes[idx],
                textAlign: TextAlign.center,
                maxLength: 1,
                textCapitalization: TextCapitalization.characters,
                style: AppTypography.heading.copyWith(
                  color: hasFill ? p.accent : p.textMuted,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: p.accent,
                onChanged: (v) => _onCodeSlotChanged(idx, v),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                ],
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(
                      color: hasFill ? p.borderHighlight : p.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(
                      color: hasFill ? p.borderHighlight : p.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: p.borderHighlight),
                  ),
                  filled: true,
                  fillColor: hasFill ? p.accentGhost : p.surface,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
