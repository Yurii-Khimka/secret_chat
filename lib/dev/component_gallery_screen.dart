// DEV ONLY — This screen will be unreachable from the production Home screen
// after Task 5. It exists solely to visually verify all components and themes.

import 'package:flutter/material.dart';
import '../tokens/tokens.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_name.dart';
import '../theme/theme_controller.dart';
import '../components/app_scaffold.dart';
import '../components/app_button.dart';
import '../components/app_text_field.dart';
import '../components/app_text.dart';
import '../components/message_bubble.dart';
import '../components/room_code_display.dart';
import '../components/pulse_dot.dart';
import '../components/system_message.dart';

class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({
    super.key,
    required this.theme,
    required this.controller,
  });

  final AppTheme theme;
  final ThemeController controller;

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  final _filledController = TextEditingController(text: 'secret phrase');
  final _emptyController = TextEditingController();

  @override
  void dispose() {
    _filledController.dispose();
    _emptyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.theme.palette;

    return AppScaffold(
      palette: p,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Theme picker ────────────────────────────
            _SectionLabel(text: '// THEME', palette: p),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: AppThemeName.values.map((name) {
                final isActive = name == widget.controller.current;
                return GestureDetector(
                  onTap: () => widget.controller.setTheme(name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? p.accent : p.surface,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: isActive ? p.accent : p.borderHighlight,
                      ),
                    ),
                    child: Text(
                      name.name.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: isActive ? p.accentText : p.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ── AppText ─────────────────────────────────
            _SectionLabel(text: '// APP TEXT', palette: p),
            const SizedBox(height: AppSpacing.md),
            AppText(text: 'Heading variant', palette: p, variant: AppTextVariant.heading),
            const SizedBox(height: AppSpacing.sm),
            AppText(text: 'Body variant — default text style', palette: p),
            const SizedBox(height: AppSpacing.sm),
            AppText(text: 'Mono variant — smaller monospace', palette: p, variant: AppTextVariant.mono),
            const SizedBox(height: AppSpacing.sm),
            AppText(text: 'CAPTION VARIANT', palette: p, variant: AppTextVariant.caption),
            const SizedBox(height: AppSpacing.sm),
            AppText(text: 'Accent colored', palette: p, color: p.accent),

            const SizedBox(height: AppSpacing.xxxl),

            // ── AppButton ───────────────────────────────
            _SectionLabel(text: '// APP BUTTON', palette: p),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Create Room',
              palette: p,
              onPressed: () {},
              expand: true,
              sub: 'Generates a new code + key pair',
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Join Room',
              palette: p,
              variant: AppButtonVariant.secondary,
              onPressed: () {},
              expand: true,
              sub: 'Enter a code shared with you',
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Primary disabled',
              palette: p,
              enabled: false,
              expand: true,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Secondary disabled',
              palette: p,
              variant: AppButtonVariant.secondary,
              enabled: false,
              expand: true,
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ── AppTextField ────────────────────────────
            _SectionLabel(text: '// APP TEXT FIELD', palette: p),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              palette: p,
              label: 'Nickname (optional)',
              placeholder: 'e.g. a.b. · knight · m',
              controller: _emptyController,
              prefixChar: '@',
              trailingText: 'LOCAL ONLY',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              palette: p,
              label: 'Password (optional)',
              placeholder: 'type to derive a key',
              controller: _filledController,
              obscure: true,
              prefixChar: '\$',
              trailingText: 'SHA-256 ▸ AES-256',
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ── MessageBubble ───────────────────────────
            _SectionLabel(text: '// MESSAGE BUBBLE', palette: p),
            const SizedBox(height: AppSpacing.md),
            MessageBubble(
              text: 'are you there',
              direction: MessageDirection.received,
              palette: p,
              senderLabel: 'PEER',
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            MessageBubble(
              text: 'yes. line is clean.',
              direction: MessageDirection.sent,
              palette: p,
              senderLabel: 'YOU',
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            MessageBubble(
              text: 'check your earlier note.\nfourth paragraph, second line.',
              direction: MessageDirection.sent,
              palette: p,
              senderLabel: 'YOU',
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            MessageBubble(
              text: 'when this room closes — gone, right?',
              direction: MessageDirection.received,
              palette: p,
              senderLabel: 'a.b.',
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ── SystemMessage ───────────────────────────
            _SectionLabel(text: '// SYSTEM MESSAGE', palette: p),
            const SizedBox(height: AppSpacing.md),
            SystemMessage(text: '— session opened —', palette: p),
            SystemMessage(text: 'peer joined · key verified ✓', palette: p),

            const SizedBox(height: AppSpacing.xxxl),

            // ── RoomCodeDisplay ─────────────────────────
            _SectionLabel(text: '// ROOM CODE DISPLAY', palette: p),
            const SizedBox(height: AppSpacing.md),
            RoomCodeDisplay(
              code: 'WOLF-7342',
              palette: p,
              onCopy: () {},
            ),
            const SizedBox(height: AppSpacing.md),
            RoomCodeDisplay(
              code: 'BETA-0001',
              palette: p,
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ── PulseDot ────────────────────────────────
            _SectionLabel(text: '// PULSE DOT', palette: p),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                PulseDot(palette: p),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'ENCRYPTED',
                  style: AppTypography.micro.copyWith(color: p.textSecondary),
                ),
                const SizedBox(width: AppSpacing.xl),
                PulseDot(palette: p, size: 10),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'ONLINE',
                  style: AppTypography.micro.copyWith(color: p.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ── AppScaffold note ────────────────────────
            _SectionLabel(text: '// APP SCAFFOLD', palette: p),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This gallery itself is wrapped in AppScaffold — background color and safe areas are applied.',
              style: AppTypography.mono.copyWith(color: p.textSecondary),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.palette});

  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(color: palette.textMuted),
    );
  }
}
