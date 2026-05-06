import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/tokens.dart';
import '../theme/app_theme.dart';
import '../components/app_scaffold.dart';
import '../components/app_button.dart';
import '../components/app_text_field.dart';
import '../components/app_toggle.dart';
import '../components/pulse_dot.dart';
import '../components/room_code_display.dart';
import '../components/system_message.dart';
import '../network/chat_client.dart';
import 'chat_screen.dart';

class RoomSetupScreen extends StatefulWidget {
  const RoomSetupScreen({
    super.key,
    required this.theme,
    required this.chatClient,
  });

  final AppTheme theme;
  final ChatClient chatClient;

  @override
  State<RoomSetupScreen> createState() => _RoomSetupScreenState();
}

class _RoomSetupScreenState extends State<RoomSetupScreen> {
  final _nicknameController = TextEditingController();
  bool _passwordMode = false;
  bool _generating = false;
  bool _codeGenerated = false;
  bool _copied = false;

  void _copyCode() {
    final code = widget.chatClient.roomCode;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _onClientChanged() {
    if (!mounted) return;
    final client = widget.chatClient;
    if (client.state == ChatConnectionState.connected && _generating) {
      _generating = false;
      setState(() => _codeGenerated = true);
    } else if (client.state == ChatConnectionState.paired) {
      client.removeListener(_onClientChanged);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            theme: widget.theme,
            chatClient: client,
          ),
        ),
      );
    } else if (client.state == ChatConnectionState.error && _generating) {
      _generating = false;
      setState(() {});
    }
  }

  Future<void> _generateCode() async {
    setState(() => _generating = true);
    widget.chatClient.addListener(_onClientChanged);
    await widget.chatClient.createRoom(
      passwordMode: _passwordMode,
      nickname: _nicknameController.text,
    );
    _onClientChanged();
  }

  @override
  void initState() {
    super.initState();
    widget.chatClient.addListener(_onClientChanged);
  }

  @override
  void dispose() {
    widget.chatClient.removeListener(_onClientChanged);
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.theme.palette;
    final code = widget.chatClient.roomCode ?? '----';

    return AppScaffold(
      palette: p,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TermHeader ─────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          widget.chatClient.close();
                          Navigator.of(context).pop();
                        },
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
                        _codeGenerated ? 'ROOM CREATED' : 'ROOM SETUP',
                        style: AppTypography.caption.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                  if (_codeGenerated)
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

                    // ── Code display ────────────────────
                    Text(
                      _codeGenerated ? '// SHARE THIS CODE' : '// ROOM CODE',
                      style: AppTypography.caption.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.md + 2),

                    if (_codeGenerated) ...[
                      RoomCodeDisplay(
                        code: code,
                        palette: p,
                        onCopy: _copyCode,
                      ),
                      if (_copied) ...[
                        const SizedBox(height: AppSpacing.sm),
                        SystemMessage(text: 'code copied', palette: p),
                      ],
                    ] else
                      Center(
                        child: Text(
                          '----',
                          style: AppTypography.heading.copyWith(
                            color: p.textMuted,
                            fontSize: 28,
                            letterSpacing: 8,
                          ),
                        ),
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
                      enabled: !_codeGenerated,
                      maxLength: 24,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '// optional — visible only to you (peer-visible nicknames arrive later)',
                      style: AppTypography.caption.copyWith(color: p.textMuted),
                    ),

                    // ── Password mode toggle ────────────
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'PASSWORD MODE',
                              style: AppTypography.caption.copyWith(color: p.textSecondary),
                            ),
                            if (_codeGenerated) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '[locked]',
                                style: AppTypography.micro.copyWith(color: p.textMuted),
                              ),
                            ],
                          ],
                        ),
                        AppToggle(
                          value: _passwordMode,
                          palette: p,
                          onChanged: _codeGenerated ? null : (v) => setState(() => _passwordMode = v),
                        ),
                      ],
                    ),
                    if (_passwordMode) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '// you and your peer will need to agree on a shared phrase before chatting. type it as your first message.',
                        style: AppTypography.caption.copyWith(color: p.textMuted),
                      ),
                    ],

                    // ── Steps (code generated state) ────
                    if (_codeGenerated) ...[
                      const SizedBox(height: AppSpacing.lg + 2),
                      Text(
                        'Share this code through any channel\noutside this app.',
                        style: AppTypography.mono.copyWith(color: p.textSecondary),
                      ),
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
                            if (_passwordMode) ...[
                              const SizedBox(height: AppSpacing.sm + 2),
                              _StepRow(n: '03', text: 'Agree on a shared phrase out of band', palette: p),
                            ],
                            const SizedBox(height: AppSpacing.sm + 2),
                            _StepRow(
                              n: _passwordMode ? '04' : '03',
                              text: 'Wait — peer will appear here',
                              palette: p,
                              live: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Generate Code CTA ──────────────────────
            if (!_codeGenerated) ...[
              AppButton(
                label: _generating ? 'Connecting...' : 'Generate Code',
                palette: p,
                expand: true,
                enabled: !_generating,
                onPressed: _generating ? null : _generateCode,
              ),
              const SizedBox(height: AppSpacing.xl),
            ] else
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
