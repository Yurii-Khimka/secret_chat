import 'dart:async';
import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

class Caret extends StatefulWidget {
  const Caret({
    super.key,
    required this.palette,
    this.color,
    this.height = 22,
    this.width = 10,
  });

  final AppPalette palette;
  final Color? color;
  final double height;
  final double width;

  @override
  State<Caret> createState() => _CaretState();
}

class _CaretState extends State<Caret> {
  bool _visible = true;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _visible = !_visible);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _visible ? 1.0 : 0.0,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color ?? widget.palette.accent,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
