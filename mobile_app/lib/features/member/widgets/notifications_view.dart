import 'package:flutter/material.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key, required this.palette, required this.onBack});

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final List<Map<String, String>> notifs = [
      {
        'title': 'Membresía activa',
        'desc':
            'Tu membresía ha sido renovada exitosamente hasta el 4 de junio.',
        'time': 'Hace 2 horas',
      },
      {
        'title': 'Nueva Rutina Asignada',
        'desc':
            'El Coach Carlos Mendoza te ha asignado la rutina Push · Pecho + Hombros.',
        'time': 'Ayer',
      },
      {
        'title': 'Alerta de pago próximo',
        'desc': 'Recuerda que tu plan vence el 4 de junio de 2026.',
        'time': 'Hace 3 días',
      },
    ];

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
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final n = notifs[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: palette.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['title']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n['desc']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n['time']!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
