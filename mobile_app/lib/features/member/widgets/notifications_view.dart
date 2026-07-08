import 'package:flutter/material.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({
    super.key,
    required this.palette,
    required this.onBack,
  });

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NOTIFICACIONES',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: onBack,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 42,
                color: palette.accent,
              ),
              const SizedBox(height: 14),
              Text(
                'No hay notificaciones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cuando existan avisos de tu sede, apareceran aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
