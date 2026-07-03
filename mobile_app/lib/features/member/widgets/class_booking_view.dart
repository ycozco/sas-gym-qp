import 'package:flutter/material.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';

class ClassBookingView extends StatefulWidget {
  const ClassBookingView({
    super.key,
    required this.palette,
    required this.onBack,
  });

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<ClassBookingView> createState() => _ClassBookingViewState();
}

class _ClassBookingViewState extends State<ClassBookingView> {
  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final classes = state.schedules;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CLASES GRUPALES',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: classes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No hay clases disponibles en esta sede por el momento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.sasColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: classes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = classes[index];
                final colors = context.sasColors;
                final bookings = (c['bookings'] as List<dynamic>? ?? const []);
                final usedSpots = bookings.where((item) {
                  final booking = item as Map<String, dynamic>;
                  return booking['estado']?.toString() != 'CANCELLED';
                }).length;
                final maxSpots = (c['cupo_maximo'] as num?)?.toInt() ?? 0;
                final myStatus = c['my_booking_status']?.toString();
                final statusLabel = myStatus == 'CONFIRMED'
                    ? 'Reservado'
                    : myStatus == 'WAITLIST'
                    ? 'Lista de espera'
                    : 'Reservar';
                Color statusColor = widget.palette.accent;
                if (statusLabel == 'Reservado') {
                  statusColor = const Color(0xFF00B85C);
                }
                if (statusLabel == 'Lista de espera') {
                  statusColor = const Color(0xFFFFB300);
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: themedCardDecoration(context, radius: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['nombre_clase']?.toString() ?? 'Clase',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ).copyWith(color: colors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 13,
                                  color: colors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${c['hora_inicio']} - ${c['hora_fin']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coach: asignado por sede',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(maxSpots - usedSpots).clamp(0, 999)} cupos disp.',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: roleFilledPillButtonStyle(
                              backgroundColor: statusColor,
                              foregroundColor: readableOn(statusColor),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              minimumHeight: 36,
                            ),
                            onPressed: () async {
                              if (myStatus == 'CONFIRMED' ||
                                  myStatus == 'WAITLIST') {
                                await state.cancelSchedule(c['id'].toString());
                              } else {
                                await state.bookSchedule(c['id'].toString());
                              }
                            },
                            child: Text(
                              statusLabel,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
