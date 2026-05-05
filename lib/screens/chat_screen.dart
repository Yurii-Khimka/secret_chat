import 'package:flutter/material.dart';
import '../tokens/tokens.dart';
import '../theme/app_theme.dart';
import '../components/app_scaffold.dart';
import '../components/message_bubble.dart';
import '../components/system_message.dart';
import '../components/pulse_dot.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.theme,
    required this.roomCode,
  });

  final AppTheme theme;
  final String roomCode;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  // Dummy seed messages — real messages will come from WebSocket layer in a later phase.
  final List<_ChatMessage> _messages = [
    _ChatMessage(text: '— session opened —', type: _MsgType.system),
    _ChatMessage(text: 'peer joined · key verified ✓', type: _MsgType.system),
    _ChatMessage(text: 'are you there', type: _MsgType.received, sender: 'PEER'),
    _ChatMessage(text: 'yes. line is clean.', type: _MsgType.sent, sender: 'YOU'),
    _ChatMessage(text: 'good. send the doc reference.', type: _MsgType.received, sender: 'PEER'),
    _ChatMessage(
      text: 'check your earlier note.\nfourth paragraph, second line.',
      type: _MsgType.sent,
      sender: 'YOU',
    ),
    _ChatMessage(text: 'got it.', type: _MsgType.received, sender: 'PEER'),
  ];

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, type: _MsgType.sent, sender: 'YOU'));
    });
    _inputController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDurations.fast,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.theme.palette;

    return AppScaffold(
      palette: p,
      // ── Top bar ────────────────────────────────────
      topBar: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg + 2,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          ),
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
                        Text(
                          widget.roomCode,
                          style: AppTypography.body.copyWith(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        PulseDot(palette: p),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'ENCRYPTED',
                          style: AppTypography.micro.copyWith(color: p.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm - 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FP 4F:9A:21:C0',
                      style: AppTypography.micro.copyWith(color: p.textMuted),
                    ),
                    Text(
                      'ANONYMOUS',
                      style: AppTypography.micro.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.border),
        ],
      ),
      // ── Messages ───────────────────────────────────
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg.type == _MsgType.system) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                    child: SystemMessage(text: msg.text, palette: p),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                  child: Align(
                    alignment: msg.type == _MsgType.sent
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: MessageBubble(
                      text: msg.text,
                      direction: msg.type == _MsgType.sent
                          ? MessageDirection.sent
                          : MessageDirection.received,
                      palette: p,
                      senderLabel: msg.sender,
                    ),
                  ),
                );
              },
            ),
          ),
          // ── Bottom input ────────────────────────────
          Divider(height: 1, color: p.border),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 2,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 50),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: p.surface,
                      border: Border.all(color: p.borderHighlight),
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '›',
                          style: AppTypography.body.copyWith(color: p.accent, fontSize: 13),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            style: AppTypography.body.copyWith(color: p.textPrimary),
                            cursorColor: p.accent,
                            cursorWidth: 8,
                            cursorHeight: 14,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              border: InputBorder.none,
                              hintText: 'message',
                              hintStyle: AppTypography.body.copyWith(color: p.textMuted),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _send,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm + 2,
                              vertical: AppSpacing.sm - 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.accent,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Text(
                              'SEND',
                              style: AppTypography.caption.copyWith(
                                color: p.accentText,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm - 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AES-256-GCM',
                        style: AppTypography.micro.copyWith(color: p.textMuted),
                      ),
                      Text(
                        'TAP TO TYPE',
                        style: AppTypography.micro.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MsgType { system, sent, received }

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.type,
    this.sender,
  });

  final String text;
  final _MsgType type;
  final String? sender;
}
