import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:hive/hive.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/local_image_picker.dart';
import '../../../data/gym_seed.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';
import '../widgets/workout_assistant_view.dart';
import '../widgets/pay_membership_view.dart';
import '../widgets/full_qr_view.dart';

MemberRecord _getLoggedMember(GymState state) {
  final user = state.currentUser;
  final backendPayments = state.memberPayments;
  return state.allMembersIncludingSoftDeleted.firstWhere(
    (m) => m.dni == user?.dni,
    orElse: () {
      if (user != null) {
        return MemberRecord(
          dni: user.dni ?? '',
          name: user.nombreCompleto,
          phone: user.celular ?? '',
          email: user.email,
          startDate: 'Hoy',
          goal: user.memberProfile?['objetivo'] ?? 'Hipertrofia',
          sessions: 0,
          lastSeen: 'Hoy',
          state: (user.memberships != null && user.memberships!.isNotEmpty)
              ? user.memberships!.first['estado']?.toString().toLowerCase() ??
                    'expired'
              : (user.estado == 'ACTIVE' ? 'active' : 'expired'),

          assignedTrainer:
              user.memberProfile?['trainer_name']?.toString() ??
              'Carlos Mendoza',
          paymentHistory: backendPayments,
          physicalMeasurements: {
            'peso':
                (user.memberProfile?['peso_kg'] as num?)?.toDouble() ?? 70.0,
            'altura':
                (user.memberProfile?['altura_cm'] as num?)?.toDouble() ?? 170.0,
          },
          progressImages: [],
        );
      }
      return state.allMembersIncludingSoftDeleted.first;
    },
  );
}

class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key});

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  int _currentTab = 0;

  // Navigation Stack Router
  final List<Map<String, dynamic>> _historyStack = [];

  void _go(String screen, [Map<String, dynamic>? params]) {
    setState(() {
      _historyStack.add({'screen': screen, 'params': params});
    });
  }

  void _back() {
    if (_historyStack.isNotEmpty) {
      setState(() {
        _historyStack.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = rolePalettes[GymRole.member]!;

    // Check if we have an active full-screen view that hides bottom bar
    bool hideNav = false;
    Widget? activeView;

    if (_historyStack.isNotEmpty) {
      final top = _historyStack.last;
      final String screen = top['screen'];

      if (screen == 'assistant') {
        hideNav = true;
        activeView = WorkoutAssistantView(palette: palette, onBack: _back);
      } else if (screen == 'qr-full') {
        hideNav = true;
        activeView = FullQRView(palette: palette, onBack: _back);
      } else if (screen == 'pay') {
        activeView = PayMembershipView(palette: palette, onBack: _back);
      } else if (screen == 'classes') {
        activeView = _ClassBookingView(palette: palette, onBack: _back);
      } else if (screen == 'observation') {
        activeView = ReportObservationView(palette: palette, onBack: _back);
      } else if (screen == 'notifications') {
        activeView = _NotificationsView(palette: palette, onBack: _back);
      }
    }

    if (activeView != null) {
      if (hideNav) {
        return activeView;
      }
      return Column(children: [Expanded(child: activeView)]);
    }

    // Default tabbed view
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildTab(
                _currentTab,
                palette,
                key: ValueKey<int>(_currentTab),
              ),
            ),
          ),
          RoleNavBar(
            currentIndex: _currentTab,
            accent: palette.accent,
            accentInk: palette.accentInk,
            onChanged: (index) => setState(() => _currentTab = index),
            items: const [
              RoleNavItem(icon: Icons.home_rounded, label: 'Inicio'),
              RoleNavItem(icon: Icons.calendar_month_rounded, label: 'Agenda'),
              RoleNavItem(
                icon: Icons.workspace_premium_rounded,
                label: 'Planes',
              ),
              RoleNavItem(icon: Icons.person_rounded, label: 'Perfil'),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _go('qr-full'),
        backgroundColor: palette.accent,
        foregroundColor: palette.accentInk,
        shape: const CircleBorder(),
        tooltip: 'Acceso QR',
        child: const Icon(Icons.qr_code_2_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildTab(int tab, RolePalette palette, {Key? key}) {
    switch (tab) {
      case 0:
        return _MemberHomePage(key: key, palette: palette, onGo: _go);
      case 1:
        return _MemberAgendaPage(key: key, palette: palette, onGo: _go);
      case 2:
        return _MemberSubscriptionPage(key: key, palette: palette, onGo: _go);
      default:
        return _MemberProfilePage(key: key, palette: palette, onGo: _go);
    }
  }
}

// ==========================================
// TABS
// ==========================================

class _MemberHomePage extends StatelessWidget {
  const _MemberHomePage({super.key, required this.palette, required this.onGo});

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final mateo = _getLoggedMember(state);

    final isExpired = mateo.state == 'expired';
    final isGrace = mateo.state == 'grace';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
      children: [
        RoleHeroHeader(
          palette: palette,
          title: 'Panel del Socio',
          subtitle: 'Accede rÃ¡pido a tus clases, membresÃ­a y QR de ingreso.',
        ),
        const SizedBox(height: 16),
        _HeroCard(palette: palette, member: mateo, onGo: onGo),
        const SizedBox(height: 16),

        // Alert banners if expired or grace
        if (isExpired)
          _buildAlertBanner(
            context,
            'MEMBRESÃA VENCIDA',
            'Tu pase ha expirado. Renueva en lÃ­nea para reactivar tu cÃ³digo QR de acceso.',
            Colors.redAccent,
            Icons.error_outline,
            'Pagar ahora',
            () => onGo('pay'),
          ),
        if (isGrace)
          _buildAlertBanner(
            context,
            'DÃA DE GRACIA ACTIVO',
            'Tu membresÃ­a venciÃ³ ayer. Tienes acceso permitido solo por hoy. Por favor regulariza tu plan.',
            const Color(0xFFFFB300),
            Icons.warning_amber_rounded,
            'Renovar plan',
            () => onGo('pay'),
          ),

        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                icon: Icons.calendar_month,
                label: 'Esta semana',
                value: '${mateo.sessions} asists.',
                note: 'Racha activa',
                accent: palette.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                icon: Icons.workspace_premium,
                label: 'Estado',
                value: mateo.state == 'active'
                    ? 'Activo'
                    : mateo.state == 'grace'
                    ? 'Gracia'
                    : 'Vencido',
                note: mateo.state == 'active'
                    ? 'Vence el 4 de jun'
                    : 'Sin dÃ­as restantes',
                accent: mateo.state == 'active'
                    ? const Color(0xFF00B85C)
                    : mateo.state == 'grace'
                    ? const Color(0xFFFFB300)
                    : Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Action shortcuts
        SectionHeader(title: 'Acciones RÃ¡pidas'),
        Row(
          children: [
            Expanded(
              child: ActionTile(
                icon: Icons.groups_rounded,
                label: 'Clases Grupales',
                note: 'Reserva tu cupo',
                accent: palette.accent,
                onTap: () => onGo('classes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionTile(
                icon: Icons.rate_review_rounded,
                label: 'Sugerencias',
                note: 'Enviar sugerencia',
                accent: palette.accent,
                onTap: () => onGo('observation'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),
        SectionHeader(title: 'Avisos del Gimnasio'),
        Builder(
          builder: (context) {
            final colors = context.sasColors;
            final box = Hive.isBoxOpen('gym_cache')
                ? Hive.box('gym_cache')
                : null;
            final List<dynamic> dismissedIds = box != null
                ? box.get('dismissed_banner_ids', defaultValue: [])
                : [];
            final activeAnnouncements = state.announcements.where((item) {
              final key = item.id.isNotEmpty ? item.id : item.title;
              return !dismissedIds.contains(key);
            }).toList();

            if (activeAnnouncements.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(context),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF00B85C),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay avisos pendientes hoy.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: activeAnnouncements.map((item) {
                Color severityColor;
                String label;

                final sev = item.severidad.toUpperCase();
                if (sev == 'WARNING' || item.tag == 'AVISO') {
                  severityColor = const Color(0xFFFFB300);
                  label = 'AVISO';
                } else if (sev == 'DANGER' ||
                    sev == 'ALERT' ||
                    item.tag == 'ALERTA') {
                  severityColor = Colors.redAccent;
                  label = 'ALERTA';
                } else {
                  severityColor = const Color(0xFF7A5AE0); // Violeta elÃ©ctrico
                  label = 'INFO';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(context),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 56,
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  StatusPill(
                                    label: label,
                                    color: severityColor,
                                    solid: true,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.time,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: colors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.detail,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.textSecondary,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colors.textMuted,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final key = item.id.isNotEmpty
                                ? item.id
                                : item.title;
                            state.dismissAnnouncement(key);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlertBanner(
    BuildContext context,
    String title,
    String text,
    Color color,
    IconData icon,
    String btnText,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF2C2C2C),
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: roleFilledPillButtonStyle(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumHeight: 36,
            ),
            onPressed: onTap,
            child: Text(
              btnText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return themedCardDecoration(context, radius: 12);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.palette,
    required this.member,
    required this.onGo,
  });

  final RolePalette palette;
  final MemberRecord member;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: palette.gradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: 'SOCIO SAS',
                color: palette.accent,
                solid: true,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                ),
                onPressed: () => onGo('notifications'),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: const Text(
                  'MS',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hola, ${member.name.split(' ')[0]} ðŸ‘‹',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tienes tu rutina lista para hoy. MantÃ©n el ritmo.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF5E5E5E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAgendaPage extends StatelessWidget {
  const _MemberAgendaPage({
    super.key,
    required this.palette,
    required this.onGo,
  });

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final activeRoutine = state.activeRoutine;
    final template = activeRoutine?['template'] as Map<String, dynamic>?;
    final routineExercises =
        (template?['ejercicios'] as List<dynamic>? ?? const <dynamic>[]);
    final mappedExercises = routineExercises.map((item) {
      final row = item as Map<String, dynamic>;
      final exercise = row['exercise'] as Map<String, dynamic>? ?? const {};
      return ExerciseItem(
        name: exercise['nombre']?.toString() ?? 'Ejercicio',
        muscle: exercise['grupo_muscular']?.toString() ?? 'General',
        sets: (row['series'] as num?)?.toInt() ?? 4,
        reps: ((row['repeticiones'] as num?)?.toInt() ?? 10).toString(),
        weight: (row['peso_sugerido_kg'] as num?)?.toInt(),
        restSeconds: (row['descanso_seg'] as num?)?.toInt() ?? 60,
        icon: Icons.fitness_center_rounded,
        available: true,
      );
    }).toList();
    final scheduleRows = state.schedules.isNotEmpty
        ? state.schedules
        : memberWeek
              .map(
                (day) => {
                  'dia_semana': [day.number],
                  'nombre_clase': day.group,
                },
              )
              .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
      children: [
        const SectionHeader(title: 'Agenda Semanal'),
        const SizedBox(height: 4),

        // Week strip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(context),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scheduleRows.take(7).map((raw) {
              final rawDays = (raw['dia_semana'] as List?) ?? const [];
              final dayNumber = rawDays.isNotEmpty
                  ? ((rawDays.first as num?)?.toInt() ?? 1)
                  : 1;
              final day =
                  memberWeek[(dayNumber - 1).clamp(0, memberWeek.length - 1)];
              return Container(
                width: 68,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: day.today ? palette.accent : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: day.today ? palette.accent : const Color(0xFFE2DDD5),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      day.day,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: day.today
                            ? palette.accentInk
                            : const Color(0xFF747474),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${day.number}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: day.today
                            ? palette.accentInk
                            : const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      raw['nombre_clase']?.toString() ?? day.group,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: day.today
                            ? palette.accentInk.withValues(alpha: 0.85)
                            : const Color(0xFF7C7C7C),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 22),

        // Active workout details
        const SectionHeader(title: 'Rutina del DÃ­a'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusPill(
                    label: 'DÃA 1 (HOY)',
                    color: Color(0xFF0B0B0B),
                    solid: true,
                  ),
                  Spacer(),
                  StatusPill(
                    label: mappedExercises.isNotEmpty
                        ? '${mappedExercises.length} ejercicios'
                        : '45-50 min',
                    color: Color(0xFF0066FF),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                template?['nombre']?.toString() ?? 'Push Â· Pecho + Hombros',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mappedExercises.isNotEmpty
                    ? (template?['descripcion']?.toString() ??
                          'Rutina activa sincronizada desde el backend.')
                    : '6 ejercicios asignados Â· Enfocado en desarrollo de fuerza de empuje.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6A6A6A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => onGo('assistant'),
                icon: const Icon(Icons.play_circle_filled_rounded),
                label: const Text(
                  'Iniciar Asistente',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: roleFilledPillButtonStyle(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.accentInk,
                  minimumHeight: 52,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        const SectionHeader(title: 'Ejercicios de la Rutina'),
        Column(
          children: (mappedExercises.isNotEmpty ? mappedExercises : memberExercises)
              .map((exercise) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: _cardDecoration(context),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: palette.accent.withValues(alpha: 0.12),
                        foregroundColor: palette.accent,
                        child: Icon(exercise.icon, size: 18),
                      ),
                      title: Text(
                        exercise.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${exercise.sets} series Ã— ${exercise.reps} reps Â· ${exercise.weight != null ? "${exercise.weight} kg" : "Al fallo"} Â· descanso: ${exercise.restSeconds}s',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFFCDCDCD),
                      ),
                    ),
                  ),
                );
              })
              .toList(),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return themedCardDecoration(context, radius: 12);
  }
}

class _MemberSubscriptionPage extends StatelessWidget {
  const _MemberSubscriptionPage({
    super.key,
    required this.palette,
    required this.onGo,
  });

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final mateo = _getLoggedMember(state);
    final currentMembership = state.currentUser?.memberships?.isNotEmpty == true
        ? Map<String, dynamic>.from(
            state.currentUser!.memberships!.first as Map,
          )
        : null;
    final balance =
        state.memberPointsSummary?['balance'] as Map<String, dynamic>?;
    final planName =
        currentMembership?['plan_nombre']?.toString() ?? 'Plan Actual';
    final startDate =
        currentMembership?['fecha_inicio']?.toString().split('T').first ?? '—';
    final endDate =
        currentMembership?['fecha_vencimiento']?.toString().split('T').first ??
        '—';
    final totalPaid = (currentMembership?['monto'] as num?)?.toDouble() ?? 0;
    final points = (balance?['puntos_disponibles'] as num?)?.toInt() ?? 0;
    final earnedPoints =
        (balance?['puntos_totales_ganados'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
      children: [
        const SectionHeader(title: 'Mi MembresÃ­a'),
        const SizedBox(height: 4),

        // Progress card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Plan Actual: $planName',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  StatusPill(
                    label: mateo.state.toUpperCase(),
                    color: mateo.state == 'active'
                        ? const Color(0xFF00B85C)
                        : mateo.state == 'grace'
                        ? const Color(0xFFFFB300)
                        : Colors.redAccent,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Vigencia: del $startDate al $endDate',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF6B6B6B)),
              ),
              const SizedBox(height: 16),
              // Linear indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: mateo.state == 'active'
                      ? 0.45
                      : (mateo.state == 'grace' ? 0.05 : 0.0),
                  backgroundColor: const Color(0xFFF0EFE9),
                  color: palette.accent,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    mateo.state == 'active'
                        ? '14 dÃ­as restantes'
                        : '0 dÃ­as restantes',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'S/ ${totalPaid.toStringAsFixed(2)} pagados',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: roleFilledPillButtonStyle(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumHeight: 50,
                ),
                onPressed: () => onGo('pay'),
                child: const Text(
                  'Renovar / Pagar MembresÃ­a',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        const SectionHeader(title: 'Puntos y Fidelización'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(context),
          child: Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.stars_rounded,
                  label: 'Disponibles',
                  value: '$points',
                  note: 'Saldo actual',
                  accent: palette.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Ganados',
                  value: '$earnedPoints',
                  note: 'Histórico',
                  accent: const Color(0xFF0066FF),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        const SectionHeader(title: 'Historial de Pagos'),
        Column(
          children: mateo.paymentHistory.reversed.map((pay) {
            Color stateColor = const Color(0xFF00B85C);
            String stateText = 'Aprobado';
            if (pay.state == 'pending') {
              stateColor = const Color(0xFFFFB300);
              stateText = 'Pendiente';
            } else if (pay.state == 'rejected') {
              stateColor = Colors.redAccent;
              stateText = 'Rechazado';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(context),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        pay.method == 'Tarjeta'
                            ? Icons.credit_card_rounded
                            : Icons.phone_android_rounded,
                        color: stateColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pay.planName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pay.date} Â· via ${pay.method}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF7A7A7A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'S/ ${pay.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StatusPill(label: stateText, color: stateColor),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return themedCardDecoration(context, radius: 12);
  }
}

class _MemberProfilePage extends StatefulWidget {
  const _MemberProfilePage({
    super.key,
    required this.palette,
    required this.onGo,
  });

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  State<_MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<_MemberProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final mateo = _getLoggedMember(state);

    return Column(
      children: [
        // Tab header
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: const Color(0xFF757575),
          indicatorColor: widget.palette.accent,
          indicatorWeight: 3.5,
          tabs: const [
            Tab(text: 'Privado'),
            Tab(text: 'Social'),
            Tab(text: 'FÃ­sico'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPrivateTab(mateo),
              _buildSocialTab(state),
              _buildPhysicalTab(mateo),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateTab(MemberRecord member) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(context),
          child: Column(
            children: [
              _profileRow('DNI / IdentificaciÃ³n', member.dni),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow('Celular', member.phone),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow('Correo electrÃ³nico', member.email),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow('Fecha de inicio', member.startDate),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow('Entrenador asignado', member.assignedTrainer),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialTab(GymState state) {
    // Filter active members in gym
    final activeInGym = state.allMembersIncludingSoftDeleted
        .where((m) => m.isActiveInGym)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Mode toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(context),
          child: Row(
            children: [
              const Icon(
                Icons.share_location_rounded,
                color: Color(0xFF0066FF),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo Visible (Social)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Permitir que otros vean que estÃ¡s entrenando hoy.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: true,
                onChanged: (val) {},
                activeThumbColor: widget.palette.accent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        SectionHeader(
          title: 'Entrenando ahora en sede (${activeInGym.length})',
        ),
        if (activeInGym.isEmpty)
          const Center(
            child: Text(
              'Nadie entrenando en este momento.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeInGym.length,
              itemBuilder: (context, index) {
                final user = activeInGym[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: widget.palette.accent.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          user.name.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.name.split(' ')[0],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPhysicalTab(MemberRecord member) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        const Text(
          'Medidas AntropomÃ©tricas',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(context),
          child: Column(
            children: [
              _profileRow(
                'Peso',
                '${member.physicalMeasurements['peso'] ?? 0} kg',
              ),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow(
                'Altura',
                '${member.physicalMeasurements['altura'] ?? 0} m',
              ),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow(
                'Cintura',
                '${member.physicalMeasurements['cintura'] ?? 0} cm',
              ),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow(
                'Pecho',
                '${member.physicalMeasurements['pecho'] ?? 0} cm',
              ),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow(
                'Cadera',
                '${member.physicalMeasurements['cadera'] ?? 0} cm',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        const Text(
          'Registro Visual (Antes / DespuÃ©s)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 12),

        // Carousel mockup
        Row(
          children: [
            Expanded(
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8E4D9)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.photo_outlined,
                      size: 38,
                      color: Colors.grey,
                    ),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        color: Colors.black54,
                        child: const Text(
                          'ENERO (78 kg)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8E4D9)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.photo_outlined,
                      size: 38,
                      color: Colors.grey,
                    ),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        color: Colors.black54,
                        child: const Text(
                          'MAYO (74 kg)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _profileRow(String label, String val) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          val,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return themedCardDecoration(context, radius: 12);
  }
}

// ==========================================
// SUBVIEWS (Full Screens / Stack)
// ==========================================

class _ClassBookingView extends StatefulWidget {
  const _ClassBookingView({required this.palette, required this.onBack});

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<_ClassBookingView> createState() => _ClassBookingViewState();
}

class _ClassBookingViewState extends State<_ClassBookingView> {
  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final classes = state.schedules.isNotEmpty
        ? state.schedules
        : [
            {
              'id': 'demo-1',
              'nombre_clase': 'Crossfit WOD',
              'hora_inicio': '07:00',
              'hora_fin': '08:00',
              'my_booking_status': null,
              'cupo_maximo': 12,
              'bookings': const [],
            },
          ];
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
      body: ListView.separated(
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
          if (statusLabel == 'Reservado') statusColor = const Color(0xFF00B85C);
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
                        if (c['id'] == 'demo-1') return;
                        if (myStatus == 'CONFIRMED' || myStatus == 'WAITLIST') {
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

class ReportObservationView extends StatefulWidget {
  const ReportObservationView({
    super.key,
    required this.palette,
    required this.onBack,
  });

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<ReportObservationView> createState() => _ReportObservationViewState();
}

class _ReportObservationViewState extends State<ReportObservationView> {
  final _descCtrl = TextEditingController();
  String _category = 'Equipamiento';
  PickedLocalImage? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final file = await LocalImagePicker.pickImage();
      if (file == null) return;
      if (file.size > AppConfig.maxLocalImageBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La imagen supera el tamano maximo permitido.'),
          ),
        );
        return;
      }

      setState(() {
        _selectedFile = file;
      });
    } catch (e) {
      AppLogger.debug('Error picking image', e);
    }
  }

  Future<List<int>?> _compressImage(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return img.encodeJpg(decoded, quality: 80);
    } catch (e) {
      AppLogger.debug('Error compressing image', e);
      return null;
    }
  }

  Future<void> _submit(GymState state) async {
    if (_descCtrl.text.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      bool success = false;
      if (state.isBackendMode) {
        List<int>? fileBytes;
        String? fileName;

        if (_selectedFile != null) {
          final compressed = await _compressImage(_selectedFile!.bytes);
          if (compressed != null) {
            fileBytes = compressed;
            fileName = _selectedFile!.name.replaceAll(
              RegExp(r'\.[^.]+$'),
              '.jpg',
            );
          } else {
            fileBytes = _selectedFile!.bytes;
            fileName = _selectedFile!.name;
          }
        }

        success = await state.uploadObservationBackend(
          category: _category,
          description: _descCtrl.text,
          fileBytes: fileBytes,
          fileName: fileName,
        );
      } else {
        state.addObservation(
          _category,
          _descCtrl.text,
          state.currentUser?.nombreCompleto ?? 'Mateo Salas',
        );
        success = true;
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte enviado correctamente.'),
              backgroundColor: Color(0xFF00B85C),
            ),
          );
          widget.onBack();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al enviar el reporte. IntÃ©ntalo de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OcurriÃ³ un error inesperado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BUZÃ“N DE OBSERVACIONES',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reporta un problema o sugerencia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tu sugerencia serÃ¡ revisada por la administraciÃ³n del local.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            const Text(
              'CategorÃ­a',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Equipamiento',
                  child: Text('Equipamiento (MÃ¡quinas)'),
                ),
                DropdownMenuItem(
                  value: 'Limpieza',
                  child: Text('Limpieza y Aseo'),
                ),
                DropdownMenuItem(
                  value: 'Personal',
                  child: Text('AtenciÃ³n del Personal'),
                ),
                DropdownMenuItem(
                  value: 'Sugerencia',
                  child: Text('Sugerencia General'),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  _category = val ?? 'Equipamiento';
                });
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'DescripciÃ³n del suceso',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Detalla lo ocurrido o tu propuesta aquÃ­...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Adjuntar Foto (Opcional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _isUploading ? null : _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2DDD5)),
                ),
                child: _selectedFile != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _selectedFile!.bytes,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF00B85C),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedFile!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedFile = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      )
                    : const Column(
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 36,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Seleccionar imagen de la galerÃ­a',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 36),

            if (_isUploading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2FF3A)),
                ),
              )
            else
              ElevatedButton(
                style: roleFilledPillButtonStyle(
                  backgroundColor: widget.palette.accent,
                  foregroundColor: widget.palette.accentInk,
                  minimumHeight: 56,
                ),
                onPressed: () => _submit(state),
                child: const Text(
                  'Enviar Reporte',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView({required this.palette, required this.onBack});

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notifs = [
      {
        'title': 'MembresÃ­a Activa',
        'desc':
            'Tu membresÃ­a ha sido renovada exitosamente hasta el 4 de junio.',
        'time': 'Hace 2 horas',
      },
      {
        'title': 'Nueva Rutina Asignada',
        'desc':
            'El Coach Carlos Mendoza te ha asignado la rutina Push Â· Pecho + Hombros.',
        'time': 'Ayer',
      },
      {
        'title': 'Alerta de Pago PrÃ³ximo',
        'desc': 'Recuerda que tu plan vence el 4 de junio de 2026.',
        'time': 'Hace 3 dÃ­as',
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2DDD5)),
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
