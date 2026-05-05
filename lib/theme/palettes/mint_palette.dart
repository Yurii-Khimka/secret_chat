import 'package:flutter/painting.dart';
import '../../tokens/tokens.dart';

/// Mint — default theme. Accent: #7fe0a3 (greenSoft from screens.jsx)
const mintPalette = AppPalette(
  background: Color(0xFF0A0D0B),
  surface: Color(0xFF101512),
  surfaceMuted: Color(0xFF141A17),
  border: Color(0x14B4DCC8), // rgba(180,220,200,0.08)
  borderHighlight: Color(0x2E78E6AA), // rgba(120,230,170,0.18)
  textPrimary: Color(0xFFE2E6E2),
  textSecondary: Color(0xFF8A918A),
  textMuted: Color(0xFF525A52),
  accent: Color(0xFF7FE0A3),
  accentMuted: Color(0x8C7FE0A3), // 55% opacity
  accentText: Color(0xFF06180E),
  accentGhost: Color(0x247FE0A3), // 14% opacity
  accentGlow: Color(0x527FE0A3), // 32% opacity
  bubbleSent: Color(0x147FE0A3),
  bubbleSentText: Color(0xFFE2E6E2),
  bubbleReceived: Color(0xFF101512),
  bubbleReceivedText: Color(0xFFE2E6E2),
  warning: Color(0xFFE6C067),
);
