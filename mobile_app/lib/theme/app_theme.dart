import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme_tokens.dart';

class AppTheme {
  static TextTheme _textTheme(SasGymColors colors) {
    return TextTheme(
      bodyLarge: GoogleFonts.plusJakartaSans(color: colors.textPrimary, fontSize: 16),
      bodyMedium: GoogleFonts.plusJakartaSans(color: colors.textSecondary, fontSize: 14, height: 1.4),
      bodySmall: GoogleFonts.plusJakartaSans(color: colors.textMuted, fontSize: 12),
      titleLarge: GoogleFonts.bricolageGrotesque(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
      titleMedium: GoogleFonts.bricolageGrotesque(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      titleSmall: GoogleFonts.bricolageGrotesque(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
      labelLarge: GoogleFonts.plusJakartaSans(color: colors.textPrimary, fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.plusJakartaSans(color: colors.textSecondary, fontWeight: FontWeight.w600),
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
    const colors = SasGymColors.light;
    final seed = colors.textPrimary;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: colors.textPrimary,
      secondary: colors.accent,
      surface: colors.surface,
      error: colors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      extensions: const [colors],
      colorScheme: scheme.copyWith(
        surface: colors.surface,
        error: colors.danger,
        primary: colors.textPrimary,
        secondary: colors.accent,
      ),
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary, size: 20),
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          color: colors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border, width: 1.0),
        ),
      ),
      textTheme: _textTheme(colors),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _pillButtonStyle(colors.textPrimary, colors.surface)),
      filledButtonTheme: FilledButtonThemeData(style: _pillButtonStyle(colors.textPrimary, colors.surface)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
          foregroundColor: WidgetStatePropertyAll(colors.textPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          foregroundColor: WidgetStatePropertyAll(colors.textPrimary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceAlt,
        labelStyle: GoogleFonts.plusJakartaSans(color: colors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: colors.textMuted, fontSize: 14),
        prefixIconColor: colors.textPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.textPrimary, width: 1.5),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.textPrimary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
        indicator: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.textPrimary,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: colors.surface, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark() {
    const colors = SasGymColors.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: const [colors],
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.dark(
        primary: colors.accent,
        secondary: const Color(0xFF7A5AE0),
        surface: colors.surface,
        error: colors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary, size: 20),
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          color: colors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border, width: 1.0),
        ),
      ),
      textTheme: _textTheme(colors),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _pillButtonStyle(colors.accent, colors.accentInk)),
      filledButtonTheme: FilledButtonThemeData(style: _pillButtonStyle(colors.accent, colors.accentInk)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
          foregroundColor: WidgetStatePropertyAll(colors.textPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          foregroundColor: WidgetStatePropertyAll(colors.textPrimary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceAlt,
        labelStyle: GoogleFonts.plusJakartaSans(color: colors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: colors.textMuted, fontSize: 14),
        prefixIconColor: colors.accent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.accent,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
        indicator: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surface,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: colors.textPrimary, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
