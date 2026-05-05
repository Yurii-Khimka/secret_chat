import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

/// Animated pulse dot — appears in TermHeader and ChatScreen as a live
/// status indicator (screens.jsx Pulse component).
class PulseDot extends StatefulWidget {
  const PulseDot({
    super.key,
    required this.palette,
    this.size = 6,
  });

  final AppPalette palette;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.pulse,
    )..repeat();
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 1), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.85), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.palette.accent,
                boxShadow: [
                  BoxShadow(
                    color: widget.palette.accent,
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
