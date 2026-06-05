import 'package:flutter/material.dart';

@immutable
class SasGymColors extends ThemeExtension<SasGymColors> {
  const SasGymColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderStrong,
    required this.accent,
    required this.accentInk,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderStrong;
  final Color accent;
  final Color accentInk;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  static const light = SasGymColors(
    background: Color(0xFFF4F2EC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF8F6F1),
    surfaceElevated: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0B0B0B),
    textSecondary: Color(0xFF5C5C5C),
    textMuted: Color(0xFF767676),
    border: Color(0xFFE6E2D8),
    borderStrong: Color(0xFFD6D2C6),
    accent: Color(0xFFD2FF3A),
    accentInk: Color(0xFF0B0B0B),
    success: Color(0xFF00B85C),
    warning: Color(0xFFFFB300),
    danger: Color(0xFFFF3B30),
    info: Color(0xFF0066FF),
  );

  static const dark = SasGymColors(
    background: Color(0xFF0B0B0C),
    surface: Color(0xFF161618),
    surfaceAlt: Color(0xFF1D1D22),
    surfaceElevated: Color(0xFF222229),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF),
    textMuted: Color(0x8AFFFFFF),
    border: Color(0xFF2E2E38),
    borderStrong: Color(0xFF3A3A44),
    accent: Color(0xFFD2FF3A),
    accentInk: Color(0xFF0B0B0C),
    success: Color(0xFF00D06A),
    warning: Color(0xFFFFC247),
    danger: Color(0xFFFF6B61),
    info: Color(0xFF6EA2FF),
  );

  @override
  SasGymColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? borderStrong,
    Color? accent,
    Color? accentInk,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return SasGymColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  SasGymColors lerp(ThemeExtension<SasGymColors>? other, double t) {
    if (other is! SasGymColors) return this;
    return SasGymColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

extension SasGymThemeX on ThemeData {
  SasGymColors get sasGym => extension<SasGymColors>() ?? SasGymColors.light;
}

extension SasGymBuildContextX on BuildContext {
  SasGymColors get sasColors => Theme.of(this).sasGym;
}
