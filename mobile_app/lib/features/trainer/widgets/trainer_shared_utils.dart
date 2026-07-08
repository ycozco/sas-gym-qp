import 'package:flutter/material.dart';
import '../../../theme/app_theme_tokens.dart';

BoxDecoration trainerCardDecoration(BuildContext context) {
  final colors = context.sasColors;
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: colors.border),
  );
}
