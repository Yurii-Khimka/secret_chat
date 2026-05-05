import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.palette,
    required this.body,
    this.topBar,
    this.bottomBar,
  });

  final AppPalette palette;
  final Widget body;
  final Widget? topBar;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ?topBar,
            Expanded(child: body),
            if (bottomBar != null)
              SafeArea(
                top: false,
                child: bottomBar!,
              ),
          ],
        ),
      ),
    );
  }
}
