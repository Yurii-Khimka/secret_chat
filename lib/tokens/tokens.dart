import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
// Spacing — extracted from screens.jsx padding / gap values
// ─────────────────────────────────────────────────────────────
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double xxl = 28;
  static const double xxxl = 36;
}

// ─────────────────────────────────────────────────────────────
// Radii — from screens.jsx T.rSm / rMd / rLg / rXl
// ─────────────────────────────────────────────────────────────
class AppRadii {
  const AppRadii._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
}

// ─────────────────────────────────────────────────────────────
// Durations — from app.jsx GlobalStyles keyframes
// ─────────────────────────────────────────────────────────────
class AppDurations {
  const AppDurations._();

  static const Duration pulse = Duration(milliseconds: 1600);
  static const Duration blink = Duration(milliseconds: 1000);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 180);
}

// ─────────────────────────────────────────────────────────────
// Typography — from screens.jsx font sizes, weights, line heights
// Mono = JetBrains Mono via google_fonts
// ─────────────────────────────────────────────────────────────
class AppTypography {
  const AppTypography._();

  static TextStyle get heading => GoogleFonts.jetBrainsMono(
        fontSize: 30,
        fontWeight: FontWeight.w500,
        height: 1.15,
        letterSpacing: -0.45,
      );

  static TextStyle get body => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0.56,
      );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get caption => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 1.98,
      );

  static TextStyle get micro => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 1.6,
      );

  static TextStyle get button => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.56,
      );

  static TextStyle get bubbleLabel => GoogleFonts.jetBrainsMono(
        fontSize: 9.5,
        fontWeight: FontWeight.w400,
        height: 1.2,
        letterSpacing: 1.52,
      );
}

// ─────────────────────────────────────────────────────────────
// Palette — semantic color slots. Hex values live in palette files.
// ─────────────────────────────────────────────────────────────
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentMuted,
    required this.accentText,
    required this.accentGhost,
    required this.accentGlow,
    required this.bubbleSent,
    required this.bubbleSentText,
    required this.bubbleReceived,
    required this.bubbleReceivedText,
    required this.warning,
  });

  /// Deep near-black background — T.bg
  final Color background;

  /// Slightly elevated surface — T.surface
  final Color surface;

  /// Higher elevation surface — T.surfaceHi
  final Color surfaceMuted;

  /// Faint hairline border — T.hairline
  final Color border;

  /// Highlighted border — T.hairlineHi
  final Color borderHighlight;

  /// Primary foreground text — T.fg
  final Color textPrimary;

  /// Dimmed secondary text — T.fgDim
  final Color textSecondary;

  /// Muted text for labels/hints — T.fgMute
  final Color textMuted;

  /// Theme accent color — per-theme value from ACCENTS
  final Color accent;

  /// Dimmed accent — greenDim equivalent
  final Color accentMuted;

  /// Text on accent-filled surfaces — dark contrast color
  final Color accentText;

  /// Very faint accent tint for backgrounds — greenGhost equivalent
  final Color accentGhost;

  /// Accent glow for shadows — greenGlow equivalent
  final Color accentGlow;

  /// Sent message bubble background — accent + 0x14 alpha
  final Color bubbleSent;

  /// Sent message bubble text
  final Color bubbleSentText;

  /// Received message bubble background — T.surface
  final Color bubbleReceived;

  /// Received message bubble text
  final Color bubbleReceivedText;

  /// Warning color — T.warn
  final Color warning;
}
