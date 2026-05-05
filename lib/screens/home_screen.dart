import 'dart:math';
import 'package:flutter/material.dart';
import '../tokens/tokens.dart';
import '../theme/app_theme.dart';
import '../components/app_scaffold.dart';
import '../components/app_button.dart';
import '../components/pulse_dot.dart';
import 'room_created_screen.dart';
import 'join_room_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.theme});

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final p = theme.palette;

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
                      PulseDot(palette: p),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'SECRET / v0.4.1',
                        style: AppTypography.caption.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    'OFFLINE • E2EE',
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
                    const SizedBox(height: AppSpacing.xxxl),
                    Text(
                      '// SESSION',
                      style: AppTypography.caption.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.md + 2),
                    Text.rich(
                      TextSpan(
                        style: AppTypography.heading.copyWith(color: p.textPrimary),
                        children: [
                          const TextSpan(text: 'No accounts.\n'),
                          const TextSpan(text: 'No history.\n'),
                          TextSpan(
                            text: 'No trace',
                            style: AppTypography.heading.copyWith(color: p.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg + 2),
                    Text(
                      'Rooms exist only while open. Close the\napp — the keys are gone with you.',
                      style: AppTypography.mono.copyWith(color: p.textSecondary),
                    ),

                    // ── DiagCard (inline) ──────────────────
                    const SizedBox(height: AppSpacing.xxl),
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
                          _DiagRow(label: 'entropy', value: 'OK', ok: true, palette: p),
                          _DiagRow(label: 'transport', value: 'TLS 1.3 / TOR-OK', ok: true, palette: p),
                          _DiagRow(label: 'storage', value: 'MEMORY-ONLY', ok: true, palette: p),
                          _DiagRow(label: 'identity', value: '—', ok: true, palette: p),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom buttons ──────────────────────────
            AppButton(
              label: 'Create Room',
              palette: p,
              expand: true,
              sub: 'Generates a new code + key pair',
              onPressed: () {
                final code = _generateFakeRoomCode();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RoomCreatedScreen(
                      theme: theme,
                      roomCode: code,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Join Room',
              palette: p,
              variant: AppButtonVariant.secondary,
              expand: true,
              sub: 'Enter a code shared with you',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JoinRoomScreen(theme: theme),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md + 6),
            Center(
              child: Text(
                'NOTHING IS SAVED · NOTHING IS LOGGED',
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

String _generateFakeRoomCode() {
  const words = ['WOLF', 'BEAR', 'HAWK', 'LYNX', 'CROW', 'DEER', 'FROG', 'MOTH'];
  final rng = Random();
  final word = words[rng.nextInt(words.length)];
  final num = (rng.nextInt(9000) + 1000).toString();
  return '$word-$num';
}

class _DiagRow extends StatelessWidget {
  const _DiagRow({
    required this.label,
    required this.value,
    required this.ok,
    required this.palette,
  });

  final String label;
  final String value;
  final bool ok;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '› ',
                  style: AppTypography.mono.copyWith(color: palette.textMuted),
                ),
                TextSpan(
                  text: label,
                  style: AppTypography.mono.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              color: ok ? palette.accent : palette.warning,
            ),
          ),
        ],
      ),
    );
  }
}
