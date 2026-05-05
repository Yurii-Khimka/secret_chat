import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/tokens.dart';
import '../theme/app_theme.dart';
import '../components/app_scaffold.dart';
import '../components/app_button.dart';
import '../components/pulse_dot.dart';
import '../components/room_code_display.dart';
import '../components/system_message.dart';
import 'chat_screen.dart';

class RoomCreatedScreen extends StatefulWidget {
  const RoomCreatedScreen({
    super.key,
    required this.theme,
    required this.roomCode,
  });

  final AppTheme theme;
  final String roomCode;

  @override
  State<RoomCreatedScreen> createState() => _RoomCreatedScreenState();
}

class _RoomCreatedScreenState extends State<RoomCreatedScreen> {
  bool _copied = false;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
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
                            '‹',
                            style: AppTypography.heading.copyWith(
                              color: p.textMuted,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      PulseDot(palette: p),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'ROOM CREATED',
                        style: AppTypography.caption.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    'WAITING FOR PEER',
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
                    Text(
                      '// SHARE THIS CODE',
                      style: AppTypography.caption.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.md + 2),

                    RoomCodeDisplay(
                      code: widget.roomCode,
                      palette: p,
                      onCopy: _copyCode,
                    ),

                    if (_copied) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SystemMessage(text: 'code copied', palette: p),
                    ],

                    const SizedBox(height: AppSpacing.lg + 2),
                    Text(
                      'Share this code through any channel\noutside this app. Then optionally\nset a nickname and a password.',
                      style: AppTypography.mono.copyWith(color: p.textSecondary),
                    ),

                    // ── Steps (inline) ───────────────────
                    const SizedBox(height: AppSpacing.lg + 2),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md + 2,
                      ),
                      decoration: BoxDecoration(
                        color: p.surface,
                        border: Border.all(color: p.border),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Column(
                        children: [
                          _StepRow(n: '01', text: 'Send the code', palette: p),
                          const SizedBox(height: AppSpacing.sm + 2),
                          _StepRow(n: '02', text: 'Set a nickname (optional)', palette: p),
                          const SizedBox(height: AppSpacing.sm + 2),
                          _StepRow(n: '03', text: 'Agree on a password (optional)', palette: p),
                          const SizedBox(height: AppSpacing.sm + 2),
                          _StepRow(n: '04', text: 'Wait — peer will appear here', palette: p, live: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom buttons ──────────────────────────
            AppButton(
              label: 'Open Chat',
              palette: p,
              expand: true,
              sub: 'Locks the code to a single peer',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      theme: widget.theme,
                      roomCode: widget.roomCode,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.n,
    required this.text,
    required this.palette,
    this.live = false,
  });

  final String n;
  final String text;
  final AppPalette palette;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          n,
          style: AppTypography.mono.copyWith(
            color: live ? palette.accent : palette.textMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.mono.copyWith(
              color: live ? palette.textPrimary : palette.textSecondary,
            ),
          ),
        ),
        if (live) PulseDot(palette: palette),
      ],
    );
  }
}
