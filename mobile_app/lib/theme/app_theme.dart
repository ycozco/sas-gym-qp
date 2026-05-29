import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static TextTheme _lightTextTheme() {
    return TextTheme(
      bodyLarge: GoogleFonts.plusJakartaSans(color: const Color(0xFF0B0B0B), fontSize: 16),
      bodyMedium: GoogleFonts.plusJakartaSans(color: const Color(0xFF5C5C5C), fontSize: 14, height: 1.4),
      bodySmall: GoogleFonts.plusJakartaSans(color: const Color(0xFF767676), fontSize: 12),
      titleLarge: GoogleFonts.bricolageGrotesque(color: const Color(0xFF0B0B0B), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleMedium: GoogleFonts.bricolageGrotesque(color: const Color(0xFF0B0B0B), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
      titleSmall: GoogleFonts.bricolageGrotesque(color: const Color(0xFF0B0B0B), fontSize: 14, fontWeight: FontWeight.bold),
      labelLarge: GoogleFonts.plusJakartaSans(color: const Color(0xFF0B0B0B), fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.plusJakartaSans(color: const Color(0xFF5C5C5C), fontWeight: FontWeight.w600),
    );
  }

  static TextTheme _darkTextTheme() {
    return TextTheme(
      bodyLarge: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16),
      bodyMedium: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14, height: 1.4),
      bodySmall: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12),
      titleLarge: GoogleFonts.bricolageGrotesque(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleMedium: GoogleFonts.bricolageGrotesque(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
      titleSmall: GoogleFonts.bricolageGrotesque(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      labelLarge: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.plusJakartaSans(color: Colors.white70, fontWeight: FontWeight.w600),
    );
  }

  static ButtonStyle _pillButtonStyle(Color background, Color foreground) {
    return ButtonStyle(
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      backgroundColor: WidgetStatePropertyAll(background),
      foregroundColor: WidgetStatePropertyAll(foreground),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  static ThemeData light() {
    const seed = Color(0xFF0E0E10);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: const Color(0xFF0E0E10),
      secondary: const Color(0xFF5C5C5C),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(surface: const Color(0xFFFFFFFF)),
      scaffoldBackgroundColor: const Color(0xFFF4F2EC),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF0B0B0B), size: 20),
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          color: const Color(0xFF0B0B0B),
          fontSize: 17,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE6E2D8), width: 1.0),
        ),
      ),
      textTheme: _lightTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _pillButtonStyle(scheme.primary, Colors.white)),
      filledButtonTheme: FilledButtonThemeData(style: _pillButtonStyle(scheme.primary, Colors.white)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFFE6E2D8))),
          foregroundColor: const WidgetStatePropertyAll(Color(0xFF0B0B0B)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          foregroundColor: const WidgetStatePropertyAll(Color(0xFF0B0B0B)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F6F1),
        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF5C5C5C), fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF767676), fontSize: 14),
        prefixIconColor: const Color(0xFF0B0B0B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6E2D8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6E2D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0B0B0B), width: 1.5),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: const Color(0xFF0B0B0B),
        unselectedLabelColor: const Color(0xFF5C5C5C),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
        indicator: BoxDecoration(
          color: const Color(0xFFD2FF3A).withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF0B0B0B),
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0B0C),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD2FF3A),
        secondary: Color(0xFF7A5AE0),
        surface: Color(0xFF161618),
        error: Colors.redAccent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 20),
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161618),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2E2E38), width: 1.0),
        ),
      ),
      textTheme: _darkTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _pillButtonStyle(const Color(0xFFD2FF3A), const Color(0xFF0B0B0C))),
      filledButtonTheme: FilledButtonThemeData(style: _pillButtonStyle(const Color(0xFFD2FF3A), const Color(0xFF0B0B0C))),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFF2E2E38))),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1D1D22),
        labelStyle: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 14),
        prefixIconColor: const Color(0xFFD2FF3A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2E2E38)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2E2E38)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD2FF3A), width: 1.5),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: const Color(0xFFD2FF3A),
        unselectedLabelColor: Colors.white70,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
        indicator: BoxDecoration(
          color: const Color(0xFFD2FF3A).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF161618),
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}