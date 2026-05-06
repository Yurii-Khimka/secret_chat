import 'package:flutter/material.dart';
import '../tokens/tokens.dart';
import '../theme/app_theme.dart';
import '../components/app_scaffold.dart';
import '../components/message_bubble.dart';
import '../components/system_message.dart';
import '../components/pulse_dot.dart';
import '../network/chat_client.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.theme,
    required this.chatClient,
  });

  final AppTheme theme;
  final ChatClient chatClient;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _peerLeft = false;

  void _onClientChanged() {
    if (!mounted) return;
    if (widget.chatClient.state == ChatConnectionState.closed && !_peerLeft) {
      setState(() => _peerLeft = true);
    } else {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    widget.chatClient.addListener(_onClientChanged);
  }

  @override
  void dispose() {
    widget.chatClient.removeListener(_onClientChanged);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _composerDisabled =>
      _peerLeft || widget.chatClient.mismatchDetected;

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _composerDisabled) return;
    widget.chatClient.sendMessage(text);
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

  String _labelFor(ChatMessage msg) {
    final client = widget.chatClient;
    if (msg.fromSelf) {
      final nick = client.localNickname;
      if (nick != null) return nick.length > 24 ? nick.substring(0, 24) : nick;
      return client.isHost == true ? 'host' : 'peer';
    }
    return client.isHost == true ? 'peer' : 'host';
  }

  String get _hintText {
    if (_peerLeft) return 'room closed';
    if (widget.chatClient.mismatchDetected) return 'phrase mismatch \u2014 leave the room';
    if (widget.chatClient.passwordMode && !widget.chatClient.hasKey) return 'type the phrase\u2026';
    return 'message';
  }

  void _goHome() {
    widget.chatClient.close();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.theme.palette;
    final messages = widget.chatClient.messages;
    final code = widget.chatClient.roomCode ?? '----';
    final mismatch = widget.chatClient.mismatchDetected;
    final modeLabel = widget.chatClient.passwordMode ? 'ENCRYPTED' : 'PLAINTEXT';

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
                          onTap: _goHome,
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: Text(
                              '\u2039',
                              style: AppTypography.heading.copyWith(
                                color: p.textMuted,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          code,
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
                          _peerLeft ? 'DISCONNECTED' : 'CONNECTED',
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
                      modeLabel,
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
      body: GestureDetector(
        onTap: _composerDisabled ? _goHome : null,
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            if (mismatch)
              SystemMessage(
                text: '// phrase mismatch\nthe phrase you typed does not match the other participant\u2019s. messages cannot be decrypted. leave the room and reconnect to try again.',
                palette: p,
                tone: SystemMessageTone.warning,
              ),
            SystemMessage(
              text: widget.chatClient.passwordMode
                  ? '// phrase mode\nthis room requires a shared phrase. type the phrase you agreed on with the other participant as your first message. it acts as the encryption key \u2014 messages will be unreadable without an exact case-sensitive match.'
                  : '[open mode \u2014 messages are sent in plaintext]',
              palette: p,
              tone: SystemMessageTone.warning,
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                itemCount: messages.length + (_peerLeft ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < messages.length) {
                    final msg = messages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                      child: Align(
                        alignment: msg.fromSelf
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: MessageBubble(
                          text: msg.text,
                          direction: msg.fromSelf
                              ? MessageDirection.sent
                              : MessageDirection.received,
                          palette: p,
                          senderLabel: _labelFor(msg),
                          decryptFailed: msg.decryptFailed,
                        ),
                      ),
                    );
                  }
                  // peer_left system message
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                    child: SystemMessage(
                      text: 'peer disconnected \u2014 room closed',
                      palette: p,
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
                        border: Border.all(color: _composerDisabled ? p.border : p.borderHighlight),
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '\u203a',
                            style: AppTypography.body.copyWith(color: _composerDisabled ? p.textMuted : p.accent, fontSize: 13),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              enabled: !_composerDisabled,
                              style: AppTypography.body.copyWith(color: p.textPrimary),
                              cursorColor: p.accent,
                              cursorWidth: 8,
                              cursorHeight: 14,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                border: InputBorder.none,
                                hintText: _hintText,
                                hintStyle: AppTypography.body.copyWith(color: p.textMuted),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _composerDisabled ? null : _send,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm + 2,
                                vertical: AppSpacing.sm - 2,
                              ),
                              decoration: BoxDecoration(
                                color: _composerDisabled ? p.textMuted : p.accent,
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
                          modeLabel,
                          style: AppTypography.micro.copyWith(color: p.textMuted),
                        ),
                        Text(
                          _composerDisabled ? 'TAP ANYWHERE TO EXIT' : 'TAP TO TYPE',
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
      ),
    );
  }
}
