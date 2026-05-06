import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

enum MessageDirection { sent, received }

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.direction,
    required this.palette,
    this.senderLabel,
  });

  final String text;
  final MessageDirection direction;
  final AppPalette palette;
  final String? senderLabel;

  @override
  Widget build(BuildContext context) {
    final isSent = direction == MessageDirection.sent;

    final bgColor = isSent ? palette.bubbleSent : palette.bubbleReceived;
    final textColor = isSent ? palette.bubbleSentText : palette.bubbleReceivedText;
    final borderColor = isSent
        ? palette.accent.withValues(alpha: 0.33)
        : palette.borderHighlight;

    // Asymmetric radii — modern chat feel from screens.jsx
    final radius = isSent
        ? BorderRadius.only(
            topLeft: Radius.circular(AppRadii.lg),
            topRight: Radius.circular(AppRadii.lg),
            bottomLeft: Radius.circular(AppRadii.lg),
            bottomRight: Radius.circular(AppRadii.sm - 2),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(AppRadii.lg),
            topRight: Radius.circular(AppRadii.lg),
            bottomLeft: Radius.circular(AppRadii.sm - 2),
            bottomRight: Radius.circular(AppRadii.lg),
          );

    return Column(
      crossAxisAlignment:
          isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (senderLabel != null)
          Padding(
            padding: EdgeInsets.only(
              left: isSent ? 0 : AppSpacing.xs,
              right: isSent ? AppSpacing.xs : 0,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              senderLabel!,
              style: AppTypography.bubbleLabel.copyWith(color: palette.textMuted),
            ),
          ),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: radius,
          ),
          child: Text(
            text,
            style: AppTypography.body.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }
}
