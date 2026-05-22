import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/gym_seed.dart';
import '../data/gym_state.dart';
import '../models/gym_models.dart';
import '../widgets/app_shell.dart';
import '../widgets/shared_widgets.dart';

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
        activeView = _WorkoutAssistantView(
          palette: palette,
          onBack: _back,
        );
      } else if (screen == 'qr-full') {
        hideNav = true;
        activeView = _FullQRView(
          palette: palette,
          onBack: _back,
        );
      } else if (screen == 'pay') {
        activeView = _PayMembershipView(
          palette: palette,
          onBack: _back,
        );
      } else if (screen == 'classes') {
        activeView = _ClassBookingView(
          palette: palette,
          onBack: _back,
        );
      } else if (screen == 'observation') {
        activeView = _ReportObservationView(
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
    // Find member Mateo Salas
    final mateo = state.allMembersIncludingSoftDeleted.firstWhere(
      (m) => m.dni == '12345678',
      orElse: () => state.allMembersIncludingSoftDeleted.first,
    );

    final isExpired = mateo.state == 'expired';
    final isGrace = mateo.state == 'grace';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
      children: [
        _HeroCard(palette: palette, member: mateo, onGo: onGo),
        const SizedBox(height: 16),

        // Alert banners if expired or grace
        if (isExpired)
          _buildAlertBanner(
            context,
            'MEMBRESÍA VENCIDA',
            'Tu pase ha expirado. Renueva en línea para reactivar tu código QR de acceso.',
            Colors.redAccent,
            Icons.error_outline,
            'Pagar ahora',
            () => onGo('pay'),
          ),
        if (isGrace)
          _buildAlertBanner(
            context,
            'DÍA DE GRACIA ACTIVO',
            'Tu membresía venció ayer. Tienes acceso permitido solo por hoy. Por favor regulariza tu plan.',
            const Color(0xFFFFB300),
            Icons.warning_amber_rounded,
            'Renovar plan',
            () => onGo('pay'),
          ),

        const SizedBox(height: 8),
        Row(
          children: [
            MetricTile(
              icon: Icons.calendar_month,
              label: 'Esta semana',
              value: '${mateo.sessions} asists.',
              note: 'Racha activa',
              accent: palette.accent,
            ),
            const SizedBox(width: 12),
            MetricTile(
              icon: Icons.workspace_premium,
              label: 'Estado',
              value: mateo.state == 'active'
                  ? 'Activo'
                  : mateo.state == 'grace'
                      ? 'Gracia'
                      : 'Vencido',
              note: mateo.state == 'active' ? 'Vence el 4 de jun' : 'Sin días restantes',
              accent: mateo.state == 'active'
                  ? const Color(0xFF00B85C)
                  : mateo.state == 'grace'
                      ? const Color(0xFFFFB300)
                      : Colors.redAccent,
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Action shortcuts
        SectionHeader(title: 'Acciones Rápidas'),
        Row(
          children: [
            ActionTile(
              icon: Icons.groups_rounded,
              label: 'Clases Grupales',
              note: 'Reserva tu cupo',
              accent: palette.accent,
              onTap: () => onGo('classes'),
            ),
            const SizedBox(width: 12),
            ActionTile(
              icon: Icons.rate_review_rounded,
              label: 'Sugerencias',
              note: 'Enviar sugerencia',
              accent: palette.accent,
              onTap: () => onGo('observation'),
            ),
          ],
        ),

        const SizedBox(height: 22),
        SectionHeader(title: 'Avisos del Gimnasio'),
        Column(
          children: state.announcements.map((item) {
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
                      height: 50,
                      decoration: BoxDecoration(
                        color: palette.accent,
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
                              StatusPill(label: item.tag, color: palette.accent, solid: true),
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
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
        borderRadius: BorderRadius.circular(20),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(100, 36),
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
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8E4D9)),
      boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 8))],
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
        borderRadius: BorderRadius.circular(28),
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
            'Hola, ${member.name.split(' ')[0]} 👋',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.6),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tienes tu rutina lista para hoy. Mantén el ritmo.',
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
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: day.today ? palette.accent : const Color(0xFFE8E4D9),
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
        const SectionHeader(title: 'Rutina del Día'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  StatusPill(label: 'DÍA 1 (HOY)', color: Color(0xFF0B0B0B), solid: true),
                  Spacer(),
                  StatusPill(label: '45-50 min', color: Color(0xFF0066FF)),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Push · Pecho + Hombros',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.6),
              ),
              const SizedBox(height: 6),
              const Text(
                '6 ejercicios asignados · Enfocado en desarrollo de fuerza de empuje.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6A6A6A), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => onGo('assistant'),
                icon: const Icon(Icons.play_circle_filled_rounded),
                label: const Text('Iniciar Asistente', style: TextStyle(fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.accentInk,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    '${exercise.sets} series × ${exercise.reps} reps · ${exercise.weight != null ? "${exercise.weight} kg" : "Al fallo"} · descanso: ${exercise.restSeconds}s',
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
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8E4D9)),
      boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 8))],
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
    final mateo = state.allMembersIncludingSoftDeleted.firstWhere(
      (m) => m.dni == '12345678',
      orElse: () => state.allMembersIncludingSoftDeleted.first,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
      children: [
        const SectionHeader(title: 'Mi Membresía'),
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
                    mateo.state == 'active' ? '14 días restantes' : '0 días restantes',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Text('S/ 150 pagados', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => onGo('pay'),
                child: const Text('Renovar / Pagar Membresía', style: TextStyle(fontWeight: FontWeight.w900)),
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
                          Text('${pay.date} · via ${pay.method}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF7A7A7A))),
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
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8E4D9)),
      boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 8))],
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
    final mateo = state.allMembersIncludingSoftDeleted.firstWhere(
      (m) => m.dni == '12345678',
      orElse: () => state.allMembersIncludingSoftDeleted.first,
    );

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
            Tab(text: 'Físico'),
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
              _profileRow('DNI / Identificación', member.dni),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow('Celular', member.phone),
              const Divider(color: Color(0xFFECEAE4), height: 24),
              _profileRow('Correo electrónico', member.email),
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
                    Text('Permitir que otros vean que estás entrenando hoy.', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
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
          'Medidas Antropométricas',
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
          'Registro Visual (Antes / Después)',
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
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8E4D9)),
      boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 8))],
    );
  }
}

// ==========================================
// SUBVIEWS (Full Screens / Stack)
// ==========================================

class _FullQRView extends StatefulWidget {
  const _FullQRView({required this.palette, required this.onBack});

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<_FullQRView> createState() => _FullQRViewState();
}

class _FullQRViewState extends State<_FullQRView> {
  int _secondsLeft = 60;
  String _seed = DateTime.now().millisecondsSinceEpoch.toString();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        setState(() {
          _secondsLeft = 60;
          _seed = DateTime.now().millisecondsSinceEpoch.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final mateo = state.allMembersIncludingSoftDeleted.firstWhere(
      (m) => m.dni == '12345678',
      orElse: () => state.allMembersIncludingSoftDeleted.first,
    );

    final bool isGranted = mateo.state == 'active' || mateo.state == 'grace';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: widget.onBack,
        ),
        title: const Text('CÓDIGO DE ACCESO QR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dynamic QR pattern
              QRPattern(
                seed: _seed,
                size: 230,
                color: isGranted ? Colors.black : Colors.red[900]!,
              ),
              const SizedBox(height: 24),

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isGranted
                      ? (mateo.state == 'grace'
                          ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                          : const Color(0xFF00B85C).withValues(alpha: 0.15))
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isGranted
                        ? (mateo.state == 'grace'
                            ? const Color(0xFFFFB300)
                            : const Color(0xFF00B85C))
                        : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGranted ? Icons.check_circle : Icons.cancel,
                      color: isGranted
                          ? (mateo.state == 'grace'
                              ? const Color(0xFFFFB300)
                              : const Color(0xFF00B85C))
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isGranted
                          ? (mateo.state == 'grace'
                              ? 'ACCESO EN GRACIA'
                              : 'ACCESO CONCEDIDO')
                          : 'ACCESO DENEGADO',
                      style: TextStyle(
                        color: isGranted
                            ? (mateo.state == 'grace'
                                ? const Color(0xFFFFB300)
                                : const Color(0xFF00B85C))
                            : Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'El código se actualiza automáticamente en $_secondsLeft segundos',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                'Acerca esta pantalla al lector óptico en la entrada del establecimiento para registrar tu ingreso.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutAssistantView extends StatefulWidget {
  const _WorkoutAssistantView({required this.palette, required this.onBack});

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<_WorkoutAssistantView> createState() => _WorkoutAssistantViewState();
}

class _WorkoutAssistantViewState extends State<_WorkoutAssistantView> {
  int _exerciseIndex = 0;
  int _setIndex = 0; // 0 to sets-1
  bool _isResting = false;
  int _restTimeRemaining = 0;
  Timer? _restTimer;

  // Track logs
  int _completedExercisesCount = 0;
  double _totalWeightLifted = 0.0;
  final List<String> _prAlerts = [];

  void _startRest(int seconds) {
    setState(() {
      _isResting = true;
      _restTimeRemaining = seconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining > 1) {
        setState(() {
          _restTimeRemaining--;
        });
      } else {
        _stopRest();
      }
    });
  }

  void _stopRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
    });
  }

  void _addRestSeconds(int seconds) {
    setState(() {
      _restTimeRemaining += seconds;
    });
  }

  void _nextSet(ExerciseItem current) {
    _stopRest();

    // Accumulate stats
    _totalWeightLifted += (current.weight ?? 0) * (int.tryParse(current.reps.split('-')[0]) ?? 10);

    if (_setIndex < current.sets - 1) {
      setState(() {
        _setIndex++;
      });
      // Trigger rest ring countdown
      _startRest(current.restSeconds);
    } else {
      // Done with all sets of this exercise
      _completedExercisesCount++;
      _nextExercise();
    }
  }

  void _nextExercise() {
    _stopRest();
    if (_exerciseIndex < memberExercises.length - 1) {
      setState(() {
        _exerciseIndex++;
        _setIndex = 0;
      });
    } else {
      // Finished workout! Set index to -1 to trigger final finished screen
      setState(() {
        _exerciseIndex = memberExercises.length;
      });
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalExercises = memberExercises.length;

    // Summary/Finished screen
    if (_exerciseIndex >= totalExercises) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD2FF3A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events, size: 48, color: Colors.black),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡ENTRENAMIENTO COMPLETADO!',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Has registrado con éxito tu sesión del día.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13.5),
                ),
                const SizedBox(height: 32),

                // Stats container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF2C2C2C)),
                  ),
                  child: Column(
                    children: [
                      _finishedStatRow('Ejercicios realizados', '$_completedExercisesCount / $totalExercises'),
                      const Divider(color: Color(0xFF2C2C2C), height: 24),
                      _finishedStatRow('Volumen levantado', '${_totalWeightLifted.round()} kg'),
                      const Divider(color: Color(0xFF2C2C2C), height: 24),
                      _finishedStatRow('Duración aproximada', '48 min'),
                      const Divider(color: Color(0xFF2C2C2C), height: 24),
                      _finishedStatRow('Nuevos Récords (PR)', 'Press de banca (70 kg) 🎉'),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD2FF3A),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size.fromHeight(54),
                  ),
                  onPressed: () {
                    // Update check-in or logs if necessary
                    widget.onBack();
                  },
                  child: const Text('Volver a Inicio', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentExercise = memberExercises[_exerciseIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            // Confirm quit
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text('¿Abandonar entrenamiento?', style: TextStyle(color: Colors.white)),
                content: const Text('Tu progreso de series registradas hoy no se guardará.', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Continuar', style: TextStyle(color: Color(0xFFD2FF3A))),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onBack();
                    },
                    child: const Text('Salir', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          'ASISTENTE: EJERCICIO ${_exerciseIndex + 1} DE $totalExercises',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(22.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Exercise core block
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        currentExercise.name,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Musculo: ${currentExercise.muscle} · Meta: ${currentExercise.sets} series de ${currentExercise.reps} reps',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),

                      // Set Pips
                      Row(
                        children: List.generate(currentExercise.sets, (idx) {
                          final isCompleted = idx < _setIndex;
                          final isActive = idx == _setIndex;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFFD2FF3A)
                                    : isActive
                                        ? const Color(0xFF0066FF)
                                        : const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Anim and Timer Stack
                      if (_isResting)
                        Center(
                          child: TimerRing(
                            secondsRemaining: _restTimeRemaining,
                            totalSeconds: currentExercise.restSeconds,
                            color: widget.palette.accent,
                          ),
                        )
                      else
                        Center(
                          child: ExerciseAnim(
                            exerciseName: currentExercise.name,
                            size: 190,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Giant control buttons
                  Column(
                    children: [
                      if (_isResting) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF3C3C3C)),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(60),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                onPressed: () => _addRestSeconds(15),
                                child: const Text('+15s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C2C2C),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(60),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                onPressed: _stopRest,
                                child: const Text('Saltar Descanso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD2FF3A),
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(68),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            // Show effort logger dialog
                            showDialog(
                              context: context,
                              builder: (ctx) => LogEffortModal(
                                exerciseName: '${currentExercise.name} - Serie ${_setIndex + 1}',
                                defaultReps: currentExercise.reps,
                                defaultWeight: currentExercise.weight,
                                onSave: (reps, weight, rpe) {
                                  // Update stats with real logged weight
                                  setState(() {
                                    if (weight > (currentExercise.weight ?? 0)) {
                                      _prAlerts.add('${currentExercise.name} a $weight kg!');
                                    }
                                  });
                                  _nextSet(currentExercise);
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle, size: 26),
                          label: Text(
                            'COMPLETAR SERIE ${_setIndex + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _nextExercise,
                          child: Text(
                            'Saltar Ejercicio',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _finishedStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13.5)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
      ],
    );
  }
}

class _PayMembershipView extends StatefulWidget {
  const _PayMembershipView({required this.palette, required this.onBack});

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<_PayMembershipView> createState() => _PayMembershipViewState();
}

class _PayMembershipViewState extends State<_PayMembershipView> {
  String? _selectedPlan = 'Mensual Plata (S/ 120)';
  String _selectedMethod = 'Yape';
  bool _uploaded = false;
  String _uploadedFileName = '';
  bool _submitting = false;

  final Map<String, double> planPrices = {
    'Mensual Plata (S/ 120)': 120.0,
    'Mensual Oro (S/ 150)': 150.0,
    'Trimestral Platinium (S/ 400)': 400.0,
  };

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RENOVAR MEMBRESÍA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Select plan
          const Text('1. Selecciona tu plan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          ...List.generate(planPrices.length, (index) {
            final plan = planPrices.keys.elementAt(index);
            final isSelected = _selectedPlan == plan;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? widget.palette.accent : const Color(0xFFE8E4D9),
                  width: isSelected ? 2 : 1,
                ),
              ),
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _selectedPlan = plan;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            const Text('Acceso ilimitado a sala de máquinas y asesoría de entrenador.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Select payment method
          const Text('2. Método de Pago', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedMethod,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'Yape', child: Text('Yape (QR)')),
              DropdownMenuItem(value: 'Plin', child: Text('Plin (QR)')),
              DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta de Crédito / Débito (Culqi)')),
              DropdownMenuItem(value: 'Manual', child: Text('Depósito Bancario (Acreditación Manual)')),
            ],
            onChanged: (val) {
              setState(() {
                _selectedMethod = val ?? 'Yape';
              });
            },
          ),
          const SizedBox(height: 24),

          // Payment details depending on method
          if (_selectedMethod == 'Yape' || _selectedMethod == 'Plin') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8E4D9)),
              ),
              child: Column(
                children: [
                  const Text('Escanea este código QR desde tu app:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Container(
                    width: 140,
                    height: 140,
                    color: Colors.grey[200],
                    child: const Icon(Icons.qr_code, size: 100),
                  ),
                  const SizedBox(height: 10),
                  const Text('Número: 987-654-321', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Upload verification section (always needed for simulated flows to show approval)
          const Text('3. Comprobante de Pago', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              // Simulate file picking
              setState(() {
                _uploaded = true;
                _uploadedFileName = 'comprobante_yape_${math.Random().nextInt(9999)}.png';
              });
            },
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _uploaded ? const Color(0xFF00B85C) : const Color(0xFFFF7A1A),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: _uploaded
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF00B85C), size: 32),
                        const SizedBox(height: 8),
                        Text(_uploadedFileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        Text('Cargado correctamente (PNG, 1.4 MB)', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: Color(0xFFFF7A1A), size: 36),
                        SizedBox(height: 8),
                        Text('Simular Carga de Captura (Máx 2MB)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Formatos: JPG, PNG', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 36),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: (_uploaded && _selectedPlan != null && !_submitting)
                ? () {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _submitting = true);
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (!mounted) return;
                      final planName = _selectedPlan!.split(' (')[0];
                      final price = planPrices[_selectedPlan!]!;

                      // Submit payment
                      state.submitManualPayment(
                        memberDni: '12345678', // Mateo Salas
                        planName: planName,
                        price: price,
                        method: _selectedMethod,
                        receiptName: _uploadedFileName,
                      );

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Pago enviado para acreditación. Un administrador lo revisará.'),
                          backgroundColor: Color(0xFF0066FF),
                        ),
                      );
                      widget.onBack();
                    });
                  }
                : null,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enviar a Verificación', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

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
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8E4D9)),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: c['status'] == 'Reservado' ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
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

class _ReportObservationView extends StatefulWidget {
  const _ReportObservationView({required this.palette, required this.onBack});

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<_ReportObservationView> createState() => _ReportObservationViewState();
}

class _ReportObservationViewState extends State<_ReportObservationView> {
  final _descCtrl = TextEditingController();
  String _category = 'Equipamiento';

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BUZÓN DE OBSERVACIONES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
            const Text('Tu sugerencia será revisada por la administración del local.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 24),

            const Text('Categoría', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'Equipamiento', child: Text('Equipamiento (Máquinas)')),
                DropdownMenuItem(value: 'Limpieza', child: Text('Limpieza y Aseo')),
                DropdownMenuItem(value: 'Personal', child: Text('Atención del Personal')),
                DropdownMenuItem(value: 'Sugerencia', child: Text('Sugerencia General')),
              ],
              onChanged: (val) {
                setState(() {
                  _category = val ?? 'Equipamiento';
                });
              },
            ),
            const SizedBox(height: 20),

            const Text('Descripción del suceso', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Detalla lo ocurrido o tu propuesta aquí...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 36),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                if (_descCtrl.text.isNotEmpty) {
                  state.addObservation(_category, _descCtrl.text, 'Mateo Salas');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sugerencia enviada correctamente.'),
                      backgroundColor: Color(0xFF00B85C),
                    ),
                  );
                  widget.onBack();
                }
              },
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
      {'title': 'Membresía Activa', 'desc': 'Tu membresía ha sido renovada exitosamente hasta el 4 de junio.', 'time': 'Hace 2 horas'},
      {'title': 'Nueva Rutina Asignada', 'desc': 'El Coach Carlos Mendoza te ha asignado la rutina Push · Pecho + Hombros.', 'time': 'Ayer'},
      {'title': 'Alerta de Pago Próximo', 'desc': 'Recuerda que tu plan vence el 4 de junio de 2026.', 'time': 'Hace 3 días'},
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
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8E4D9)),
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