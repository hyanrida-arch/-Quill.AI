import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QAI {
  // Colors
  static const Color bg = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0D1117);
  static const Color muted = Color(0xFF5B6470);
  static const Color hint = Color(0xFF8A929C);
  static const Color border = Color(0xFFE6E5E0);
  static const Color borderStrong = Color(0xFF0D1117);
  static const Color field = Color(0xFFFAFAF8);
  static const Color accent = Color(0xFF0D1117);
  static const Color teal = Color(0xFF1FA493);
  static const Color cardSelected = Color(0xFFF6F5F0);
  static const Color disabledBtn = Color(0xFFC9C8C2);
  static const Color trackBg = Color(0xFFE6E5E0);

  // Typography helpers
  static TextStyle headline(double size) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.025 * size,
    height: 1.15,
  );

  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? muted,
        letterSpacing: -0.005 * size,
        height: 1.5,
      );

  static TextStyle label(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w500,
        color: color ?? ink,
        letterSpacing: -0.005 * size,
      );

  static ThemeData theme() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: ink),
    scaffoldBackgroundColor: bg,
    fontFamily: GoogleFonts.inter().fontFamily,
    useMaterial3: true,
  );
}