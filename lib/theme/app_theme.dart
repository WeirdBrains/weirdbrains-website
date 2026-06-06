import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// WeirdBrains design system. Cosmic-navy brand pulled from weirdbrains.com,
/// elevated with a display typeface, a spacing scale, and depth tokens.
class AppTheme {
  // ---- Color ----
  static const Color background = Color(0xFF001B3D); // navy (rgb 0,27,61)
  static const Color deepSpace = Color(0xFF00081A); // near-black navy floor
  static const Color surface = Color(0xFF07223F); // cards / fields
  static const Color surfaceLight = Color(0xFF0C2C52);
  static const Color border = Color(0x1FFFFFFF); // white @ 12%
  static const Color borderStrong = Color(0x3DA855F7); // purple @ 24%

  static const Color gold = Color(0xFFFACC15); // yellow-400
  static const Color purple = Color(0xFFA855F7); // purple-500
  static const Color purpleBright = Color(0xFFC084FC); // purple-400
  static const Color sky = Color(0xFF38BDF8); // sky-400 (accent variety)
  static const Color accent = purple;

  static const Color textPrimary = Color(0xFFF5F8FF);
  static const Color textSecondary = Color(0xFFA6BBD9); // bluish grey
  static const Color textMuted = Color(0xFF6B82A6);

  static const List<Color> brandGradient = [gold, purpleBright, gold];
  static const List<Color> ctaGradient = [Color(0xFFC084FC), Color(0xFF7C3AED)];

  // ---- Spacing scale ----
  static const double s4 = 4, s8 = 8, s12 = 12, s16 = 16, s24 = 24;
  static const double s32 = 32, s40 = 40, s48 = 48, s64 = 64, s80 = 80;
  static const double s96 = 96, s128 = 128, s160 = 160;

  static const double maxContent = 1120;
  static const double maxText = 720;
  static const double mobileBreak = 760;

  // ---- Type ----
  static TextStyle display(double size, {Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: size,
        height: 1.05,
        letterSpacing: -1.2,
        fontWeight: FontWeight.w700,
        color: color ?? textPrimary,
      );

  static TextStyle eyebrow() => GoogleFonts.spaceGrotesk(
        fontSize: 13,
        letterSpacing: 4,
        fontWeight: FontWeight.w600,
        color: gold,
      );

  static TextStyle heading(double size, {Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: size,
        height: 1.1,
        letterSpacing: -0.6,
        fontWeight: FontWeight.w700,
        color: color ?? textPrimary,
      );

  static TextStyle body(double size, {Color? color, double height = 1.6}) =>
      GoogleFonts.inter(
        fontSize: size,
        height: height,
        color: color ?? textSecondary,
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: purple,
          secondary: gold,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      );
}
