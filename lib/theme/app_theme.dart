import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand palette pulled from the live weirdbrains.com.
  static const Color background = Color(0xFF001B3D); // navy (rgb 0,27,61)
  static const Color deepSpace = Color(0xFF000E22); // darker band / gradient floor
  static const Color surface = Color(0xFF06203F); // cards / form fields
  static const Color surfaceLight = Color(0xFF0A2A52);

  // The signature gradient: gold -> purple -> gold.
  static const Color gold = Color(0xFFFACC15); // tailwind yellow-400
  static const Color purple = Color(0xFFA855F7); // tailwind purple-500
  static const Color accent = purple;

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9FB3D1); // bluish grey on navy

  static const List<Color> brandGradient = [gold, purple, gold];

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
