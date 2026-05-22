import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const seed = Color(0xFF0E0E10);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        surface: const Color(0xFFF7F4EE),
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F1EA),
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      ),
    );
  }
}