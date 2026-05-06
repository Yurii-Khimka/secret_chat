import 'package:flutter/material.dart';
import '../tokens/tokens.dart';
import '../theme/app_theme.dart';
import '../components/app_scaffold.dart';
import '../components/app_button.dart';
import '../components/pulse_dot.dart';
import '../components/caret.dart';
import '../security/activation_controller.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({
    super.key,
    required this.theme,
    required this.controller,
  });

  final AppTheme theme;
  final ActivationController controller;

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _textController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    widget.controller.clearError();
    setState(() {});
  }

  Future<void> _activate() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.controller.activate(_textController.text);
    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
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
            // ── TermHeader ─────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
              child: Row(
                children: [
                  PulseDot(palette: p),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'ACCESS CODE',
                    style: AppTypography.caption.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),

            // ── Body ───────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxxl),
                    Text(
                      '// ACTIVATION',
                      style: AppTypography.caption.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.md + 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Invite required',
                          style: AppTypography.heading.copyWith(color: p.accent),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Caret(palette: p),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg + 2),
                    Text(
                      'paste the access code you were sent. it\'s tied to this app, not to your identity.',
                      style: AppTypography.micro.copyWith(color: p.textSecondary),
                    ),

                    // ── Code input ──────────────────────
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      constraints: const BoxConstraints(minHeight: 100),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md + 2,
                      ),
                      decoration: BoxDecoration(
                        color: p.surface,
                        border: Border.all(color: p.border),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: 6,
                        minLines: 4,
                        style: AppTypography.mono.copyWith(color: p.textPrimary),
                        cursorColor: p.accent,
                        cursorWidth: 8,
                        cursorHeight: 14,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: 'paste activation code\u2026',
                          hintStyle: AppTypography.mono.copyWith(color: p.textMuted),
                        ),
                      ),
                    ),

                    // ── Activate button ─────────────────
                    const SizedBox(height: AppSpacing.lg),
                    ListenableBuilder(
                      listenable: widget.controller,
                      builder: (context, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppButton(
                              label: 'Activate',
                              palette: p,
                              expand: true,
                              enabled: _textController.text.trim().isNotEmpty && !_busy,
                              onPressed: _activate,
                            ),
                            if (widget.controller.error != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                widget.controller.error!,
                                style: AppTypography.mono.copyWith(color: p.warning),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ─────────────────────────────
            Center(
              child: Text(
                'NOTHING IS SAVED \u00b7 NOTHING IS LOGGED',
                style: AppTypography.micro.copyWith(color: p.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
