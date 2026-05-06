import 'package:flutter/material.dart';
import '../tokens/tokens.dart';
import '../theme/app_theme.dart';
import '../components/app_scaffold.dart';
import '../components/app_button.dart';
import '../theme/theme_controller.dart';
import '../components/pulse_dot.dart';
import '../network/chat_client.dart';
import '../components/caret.dart';
import 'room_setup_screen.dart';
import 'join_room_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.theme,
    required this.controller,
    required this.chatClient,
  });

  final AppTheme theme;
  final ThemeController controller;
  final ChatClient chatClient;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _openRoomSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomSetupScreen(
          theme: widget.theme,
          chatClient: widget.chatClient,
        ),
      ),
    );
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
                      PulseDot(palette: p),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'SECRET / v0.4.1',
                        style: AppTypography.caption.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            theme: widget.theme,
                            controller: widget.controller,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      '⚙ SETTINGS',
                      style: AppTypography.caption.copyWith(color: p.textMuted),
                    ),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No accounts.', style: AppTypography.heading.copyWith(color: p.textPrimary)),
                        Text('No history.', style: AppTypography.heading.copyWith(color: p.textPrimary)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('No trace', style: AppTypography.heading.copyWith(color: p.accent)),
                            const SizedBox(width: AppSpacing.xs),
                            Caret(palette: p),
                          ],
                        ),
                      ],
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
              onPressed: _openRoomSetup,
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
                    builder: (_) => JoinRoomScreen(
                      theme: widget.theme,
                      chatClient: widget.chatClient,
                    ),
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
                  style: AppTypography.mono.copyWith(color: palette.textMuted, height: 1.9),
                ),
                TextSpan(
                  text: label,
                  style: AppTypography.mono.copyWith(color: palette.textSecondary, height: 1.9),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              color: ok ? palette.accent : palette.warning,
              height: 1.9,
            ),
          ),
        ],
      ),
    );
  }
}
