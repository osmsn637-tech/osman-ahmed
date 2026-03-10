import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const primary = Color(0xFF0D3B66);
  static const accent = Color(0xFF0F766E);
  static const surface = Color(0xFFF1F5F8);
  static const surfaceAlt = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF102A43);
  static const textMuted = Color(0xFF486581);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const error = Color(0xFFDC2626);
  static const cardColor = Colors.white;

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.manrope(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.4),
        headlineSmall: GoogleFonts.manrope(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.3),
        titleLarge: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.2),
        titleMedium: GoogleFonts.manrope(
            fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
        bodyLarge: GoogleFonts.manrope(
            fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
        bodyMedium: GoogleFonts.manrope(
            fontSize: 14, fontWeight: FontWeight.w500, color: textMuted),
        labelLarge: GoogleFonts.manrope(
            fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.manrope(
            fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: surfaceAlt),
          textStyle:
              GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceAlt, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle:
            GoogleFonts.manrope(color: textMuted, fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.manrope(color: const Color(0xFF829AB1)),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceAlt),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle:
            GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(color: surfaceAlt, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: accent.withValues(alpha: 0.14),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.manrope(
                fontSize: 12, fontWeight: FontWeight.w800, color: accent);
          }
          return GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7B8794));
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accent, size: 24);
          }
          return const IconThemeData(color: Color(0xFF7B8794), size: 24);
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
