import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta do QFlags (a mesma do design no canvas), nas versões clara e escura.
@immutable
class QColors extends ThemeExtension<QColors> {
  const QColors({
    required this.bg,
    required this.surface,
    required this.border,
    required this.track,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.memory,
    required this.timeAttack,
    required this.halfFlag,
    required this.onAccent,
    required this.correct,
    required this.correctBg,
    required this.correctText,
    required this.wrong,
    required this.wrongBg,
    required this.wrongText,
  });

  final Color bg, surface, border, track, text, muted;
  final Color primary, onPrimary;
  final Color memory, timeAttack, halfFlag, onAccent;
  final Color correct, correctBg, correctText;
  final Color wrong, wrongBg, wrongText;

  static const light = QColors(
    bg: Color(0xFFF4F6FB),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFCBD5E1),
    track: Color(0xFFE2E8F0),
    text: Color(0xFF0F172A),
    muted: Color(0xFF475569),
    primary: Color(0xFF2747D9),
    onPrimary: Color(0xFFFFFFFF),
    memory: Color(0xFF2747D9),
    timeAttack: Color(0xFFB45309),
    halfFlag: Color(0xFF0F766E),
    onAccent: Color(0xFFFFFFFF),
    correct: Color(0xFF15803D),
    correctBg: Color(0xFFDCFCE7),
    correctText: Color(0xFF14532D),
    wrong: Color(0xFFB91C1C),
    wrongBg: Color(0xFFFEE2E2),
    wrongText: Color(0xFF7F1D1D),
  );

  static const dark = QColors(
    bg: Color(0xFF0B1020),
    surface: Color(0xFF151B30),
    border: Color(0xFF2A3352),
    track: Color(0xFF2A3352),
    text: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    primary: Color(0xFF6C8BFF),
    onPrimary: Color(0xFF0B1020),
    memory: Color(0xFF6C8BFF),
    timeAttack: Color(0xFFFFC14D),
    halfFlag: Color(0xFF2DD4BF),
    onAccent: Color(0xFF0B1020),
    correct: Color(0xFF4ADE80),
    correctBg: Color(0xFF0F2E1C),
    correctText: Color(0xFFBBF7D0),
    wrong: Color(0xFFF87171),
    wrongBg: Color(0xFF3B1219),
    wrongText: Color(0xFFFECACA),
  );

  @override
  QColors copyWith() => this;

  @override
  QColors lerp(ThemeExtension<QColors>? other, double t) =>
      other is QColors && t >= 0.5 ? other : this;
}

extension QColorsContext on BuildContext {
  QColors get colors => Theme.of(this).extension<QColors>()!;
}

/// Fonte de títulos (Space Grotesk), usada em botões grandes e placares.
TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
    GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: weight, color: color);

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? QColors.dark : QColors.light;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      surface: c.surface,
    ),
    scaffoldBackgroundColor: c.bg,
  );
  return base.copyWith(
    extensions: [c],
    textTheme: GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: c.text, displayColor: c.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      hintStyle: TextStyle(color: c.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.primary, width: 2),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
