import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class BoostDriveTheme {
  // Brand Colors - New High-end palette
  static const Color primaryColor = Color(0xFFE65100); 
  static const Color backgroundDark = Color(0xFF101B22);
  static const Color surfaceDark = Color(0xFF1A262E); 
  static const Color accentColor = Color(0xFFFF8C00);
  static const Color backgroundLight = Color(0xFFF5F7F8);
  
  static const String globalBackgroundImage = 'assets/images/range_rover_hero.png';
  
  static const Color textBody = Color(0xFFEBEBF5);
  static const Color textDim = Color(0xFF90B2CB); // Based on HTML slate-500/slate-400

  static ThemeData darkTheme(BuildContext context) {
    return _baseTheme(context, Brightness.dark);
  }

  static ThemeData lightTheme(BuildContext context) {
    return _baseTheme(context, Brightness.light);
  }

  static ThemeData _baseTheme(BuildContext context, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final surfaceColor = isDark ? surfaceDark : Colors.white;
    final textColor = isDark ? textBody : const Color(0xFF1D2939);
    final textDimColor = isDark ? textDim : const Color(0xFF667085);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textColor,
      ),
      textTheme: GoogleFonts.manropeTextTheme(
        Theme.of(context).textTheme,
      ).apply(
        bodyColor: textColor,
        displayColor: isDark ? Colors.white : const Color(0xFF101828),
        fontFamilyFallback: const ['sans-serif'],
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false, // Changed to false for left alignment
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF2F4F7), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFEAECF0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: textDimColor, fontSize: 13, fontWeight: FontWeight.bold),
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

String getInitials(String fullName) {
  if (fullName.isEmpty) return 'U';
  final parts = fullName.trim().split(' ');
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}
