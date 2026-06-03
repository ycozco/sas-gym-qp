import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import '../../../data/gym_seed.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';
import '../widgets/workout_assistant_view.dart';
import '../widgets/pay_membership_view.dart';
import '../widgets/full_qr_view.dart';

MemberRecord _getLoggedMember(GymState state) {
  final user = state.currentUser;
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
              ? user.memberships!.first['estado']?.toString().toLowerCase() ?? 'expired'
              : (user.estado == 'ACTIVE' ? 'active' : 'expired'),

          assignedTrainer: 'Carlos Mendoza',
          paymentHistory: [],
          physicalMeasurements: {
            'peso': (user.memberProfile?['peso_kg'] as num?)?.toDouble() ?? 70.0,
            'altura': (user.memberProfile?['altura_cm'] as num?)?.toDouble() ?? 170.0,
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
        activeView = WorkoutAssistantView(
          palette: palette,
          onBack: _back,
        );
      } else if (screen == 'qr-full') {
        hideNav = true;
        activeView = FullQRView(
          palette: palette,
          onBack: _back,
        );
      } else if (screen == 'pay') {
        activeView = PayMembershipView(
          palette: palette,
          onBack: _back,
        );
      } else if (screen == 'classes') {
        activeView = _ClassBookingView(
          palette: palette,
          onBack: _back,
        );
      } else if (screen == 'observation') {
        activeView = ReportObservationView(
          palette: palette,
          onBack: _back,
        );
      } else if (screen == 'notifications') {
        activeView = _NotificationsView(
          palette: palette,
          onBack: _back,
        );
      }
    }

    if (activeView != null) {
      if (hideNav) {
        return activeView;
      }
      return Column(
        children: [
          Expanded(child: activeView),
        ],
      );
    }

    // Default tabbed view
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildTab(_currentTab, palette, key: ValueKey<int>(_currentTab)),
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
              RoleNavItem(icon: Icons.workspace_premium_rounded, label: 'Planes'),
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
                note: mateo.state == 'active' ? 'Vence el 4 de jun' : 'Sin dÃ­as restantes',
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
            final box = Hive.isBoxOpen('gym_cache') ? Hive.box('gym_cache') : null;
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
                  decoration: _cardDecoration(),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00B85C), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay avisos pendientes hoy.',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
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
                } else if (sev == 'DANGER' || sev == 'ALERT' || item.tag == 'ALERTA') {
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
                    decoration: _cardDecoration(),
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
                                  StatusPill(label: label, color: severityColor, solid: true),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.time,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF7C7C7C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.detail,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white70,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white38),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final key = item.id.isNotEmpty ? item.id : item.title;
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
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF2C2C2C), fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w500),
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
            child: Text(btnText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2DDD5)),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.palette, required this.member, required this.onGo});

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
              StatusPill(label: 'SOCIO SAS', color: palette.accent, solid: true),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                onPressed: () => onGo('notifications'),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: const Text('MS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hola, ${member.name.split(' ')[0]} ðŸ‘‹',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.6),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tienes tu rutina lista para hoy. MantÃ©n el ritmo.',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF5E5E5E), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MemberAgendaPage extends StatelessWidget {
  const _MemberAgendaPage({super.key, required this.palette, required this.onGo});

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
      children: [
        const SectionHeader(title: 'Agenda Semanal'),
        const SizedBox(height: 4),

        // Week strip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: memberWeek.map((day) {
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
                        color: day.today ? palette.accentInk : const Color(0xFF747474),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${day.number}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: day.today ? palette.accentInk : const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.group,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: day.today ? palette.accentInk.withValues(alpha: 0.85) : const Color(0xFF7C7C7C),
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
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  StatusPill(label: 'DÃA 1 (HOY)', color: Color(0xFF0B0B0B), solid: true),
                  Spacer(),
                  StatusPill(label: '45-50 min', color: Color(0xFF0066FF)),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Push Â· Pecho + Hombros',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.6),
              ),
              const SizedBox(height: 6),
              const Text(
                '6 ejercicios asignados Â· Enfocado en desarrollo de fuerza de empuje.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6A6A6A), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => onGo('assistant'),
                icon: const Icon(Icons.play_circle_filled_rounded),
                label: const Text('Iniciar Asistente', style: TextStyle(fontWeight: FontWeight.w900)),
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
          children: memberExercises.map((exercise) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: _cardDecoration(),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: palette.accent.withValues(alpha: 0.12),
                    foregroundColor: palette.accent,
                    child: Icon(exercise.icon, size: 18),
                  ),
                  title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    '${exercise.sets} series Ã— ${exercise.reps} reps Â· ${exercise.weight != null ? "${exercise.weight} kg" : "Al fallo"} Â· descanso: ${exercise.restSeconds}s',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.check_circle_outline, color: Color(0xFFCDCDCD)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2DDD5)),
    );
  }
}

class _MemberSubscriptionPage extends StatelessWidget {
  const _MemberSubscriptionPage({super.key, required this.palette, required this.onGo});

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final mateo = _getLoggedMember(state);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
      children: [
        const SectionHeader(title: 'Mi MembresÃ­a'),
        const SizedBox(height: 4),

        // Progress card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Plan Actual: Oro Mensual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
              const Text('Vigencia: del 05 de mayo al 04 de junio', style: TextStyle(fontSize: 12.5, color: Color(0xFF6B6B6B))),
              const SizedBox(height: 16),
              // Linear indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: mateo.state == 'active' ? 0.45 : (mateo.state == 'grace' ? 0.05 : 0.0),
                  backgroundColor: const Color(0xFFF0EFE9),
                  color: palette.accent,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    mateo.state == 'active' ? '14 dÃ­as restantes' : '0 dÃ­as restantes',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Text('S/ 150 pagados', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
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
                child: const Text('Renovar / Pagar MembresÃ­a', style: TextStyle(fontWeight: FontWeight.w900)),
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
                decoration: _cardDecoration(),
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
                          Text(pay.planName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('${pay.date} Â· via ${pay.method}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF7A7A7A))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('S/ ${pay.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2DDD5)),
    );
  }
}

class _MemberProfilePage extends StatefulWidget {
  const _MemberProfilePage({super.key, required this.palette, required this.onGo});

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  State<_MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<_MemberProfilePage> with SingleTickerProviderStateMixin {
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
          decoration: _cardDecoration(),
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
    final activeInGym = state.allMembersIncludingSoftDeleted.where((m) => m.isActiveInGym).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Mode toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              const Icon(Icons.share_location_rounded, color: Color(0xFF0066FF)),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modo Visible (Social)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Permitir que otros vean que estÃ¡s entrenando hoy.', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
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

        SectionHeader(title: 'Entrenando ahora en sede (${activeInGym.length})'),
        if (activeInGym.isEmpty)
          const Center(child: Text('Nadie entrenando en este momento.', style: TextStyle(color: Colors.grey)))
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
                        backgroundColor: widget.palette.accent.withValues(alpha: 0.15),
                        child: Text(
                          user.name.substring(0, 2).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(user.name.split(' ')[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _profileRow('Peso', '${member.physicalMeasurements['peso'] ?? 0} kg'),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow('Altura', '${member.physicalMeasurements['altura'] ?? 0} m'),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow('Cintura', '${member.physicalMeasurements['cintura'] ?? 0} cm'),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow('Pecho', '${member.physicalMeasurements['pecho'] ?? 0} cm'),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow('Cadera', '${member.physicalMeasurements['cadera'] ?? 0} cm'),
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
                    const Icon(Icons.photo_outlined, size: 38, color: Colors.grey),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        color: Colors.black54,
                        child: const Text('ENERO (78 kg)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    const Icon(Icons.photo_outlined, size: 38, color: Colors.grey),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        color: Colors.black54,
                        child: const Text('MAYO (74 kg)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF757575), fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(val, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2DDD5)),
    );
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
  final List<Map<String, dynamic>> _classes = [
    {'name': 'Crossfit WOD', 'time': '07:00 - 08:00', 'trainer': 'Carlos M.', 'status': 'Reservar', 'spots': 3},
    {'name': 'Spinning Pro', 'time': '08:30 - 09:30', 'trainer': 'Leticia F.', 'status': 'Reservado', 'spots': 0},
    {'name': 'Funcional HIIT', 'time': '10:00 - 11:00', 'trainer': 'Carlos M.', 'status': 'Lista de espera', 'spots': 0},
    {'name': 'Yoga Flex', 'time': '18:30 - 19:30', 'trainer': 'Valeria S.', 'status': 'Reservar', 'spots': 8},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CLASES GRUPALES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _classes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = _classes[index];
          Color statusColor = widget.palette.accent;
          if (c['status'] == 'Reservado') statusColor = const Color(0xFF00B85C);
          if (c['status'] == 'Lista de espera') statusColor = const Color(0xFFFFB300);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2DDD5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(c['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Coach: ${c['trainer']}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${c['spots']} cupos disp.', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: roleFilledPillButtonStyle(
                        backgroundColor: statusColor,
                        foregroundColor: c['status'] == 'Reservado' ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumHeight: 36,
                      ),
                      onPressed: () {
                        setState(() {
                          if (c['status'] == 'Reservar') {
                            c['status'] = 'Reservado';
                            c['spots']--;
                          } else if (c['status'] == 'Reservado') {
                            c['status'] = 'Reservar';
                            c['spots']++;
                          }
                        });
                      },
                      child: Text(
                        c['status'],
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
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
  const ReportObservationView({super.key, required this.palette, required this.onBack});

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<ReportObservationView> createState() => _ReportObservationViewState();
}

class _ReportObservationViewState extends State<ReportObservationView> {
  final _descCtrl = TextEditingController();
  String _category = 'Equipamiento';
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<List<int>?> _compressImage(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return img.encodeJpg(decoded, quality: 80);
    } catch (e) {
      debugPrint('Error compressing image: $e');
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

        if (_selectedFile != null && _selectedFile!.bytes != null) {
          final compressed = await _compressImage(_selectedFile!.bytes!);
          if (compressed != null) {
            fileBytes = compressed;
            fileName = _selectedFile!.name.replaceAll(RegExp(r'\.[^.]+$'), '.jpg');
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
        state.addObservation(_category, _descCtrl.text, state.currentUser?.nombreCompleto ?? 'Mateo Salas');
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
        title: const Text('BUZÃ“N DE OBSERVACIONES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
            const Text('Reporta un problema o sugerencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Tu sugerencia serÃ¡ revisada por la administraciÃ³n del local.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 24),

            const Text('CategorÃ­a', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'Equipamiento', child: Text('Equipamiento (MÃ¡quinas)')),
                DropdownMenuItem(value: 'Limpieza', child: Text('Limpieza y Aseo')),
                DropdownMenuItem(value: 'Personal', child: Text('AtenciÃ³n del Personal')),
                DropdownMenuItem(value: 'Sugerencia', child: Text('Sugerencia General')),
              ],
              onChanged: (val) {
                setState(() {
                  _category = val ?? 'Equipamiento';
                });
              },
            ),
            const SizedBox(height: 20),

            const Text('DescripciÃ³n del suceso', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Detalla lo ocurrido o tu propuesta aquÃ­...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),

            const Text('Adjuntar Foto (Opcional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _isUploading ? null : _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2DDD5)),
                ),
                child: _selectedFile != null
                    ? Column(
                        children: [
                          if (_selectedFile!.bytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _selectedFile!.bytes!,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF00B85C), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedFile!.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
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
                          Icon(Icons.camera_alt_outlined, size: 36, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Seleccionar imagen de la galerÃ­a', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                child: const Text('Enviar Reporte', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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
      {'title': 'MembresÃ­a Activa', 'desc': 'Tu membresÃ­a ha sido renovada exitosamente hasta el 4 de junio.', 'time': 'Hace 2 horas'},
      {'title': 'Nueva Rutina Asignada', 'desc': 'El Coach Carlos Mendoza te ha asignado la rutina Push Â· Pecho + Hombros.', 'time': 'Ayer'},
      {'title': 'Alerta de Pago PrÃ³ximo', 'desc': 'Recuerda que tu plan vence el 4 de junio de 2026.', 'time': 'Hace 3 dÃ­as'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTIFICACIONES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                  child: Icon(Icons.notifications, color: palette.accent, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n['title']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(n['desc']!, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.35)),
                      const SizedBox(height: 6),
                      Text(n['time']!, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
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
