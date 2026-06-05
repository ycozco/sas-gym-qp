import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';

class AdminVerdictView extends StatefulWidget {
  const AdminVerdictView({
    super.key,
    required this.palette,
    required this.result,
    required this.member,
    required this.dni,
    required this.onBack,
    required this.onChargeDirect,
    this.membershipPlans = const [],
    this.onCreateNewClient,
  });

  final RolePalette palette;
  final String result;
  final MemberRecord? member;
  final String dni;
  final VoidCallback onBack;
  final Function(String dni, {String? planName, double? price}) onChargeDirect;
  final List<MembershipPlan> membershipPlans;
  final Function(String)? onCreateNewClient;

  @override
  State<AdminVerdictView> createState() => _AdminVerdictViewState();
}

class _AdminVerdictViewState extends State<AdminVerdictView> {
  int _secondsLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.result == 'granted') {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_secondsLeft > 1) {
            _secondsLeft--;
          } else {
            _timer?.cancel();
            widget.onBack();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    Color bg;
    IconData icon;
    String statusTitle;
    String statusSubtitle;
    bool showDirectPlans = false;

    if (widget.result == 'granted') {
      bg = colors.success;
      icon = Icons.check_circle_outline_rounded;
      statusTitle = 'ACCESO CONCEDIDO';
      statusSubtitle = 'Socio activo. El registro de asistencia fue grabado exitosamente.';
    } else if (widget.result == 'grace') {
      bg = colors.warning;
      icon = Icons.warning_amber_rounded;
      statusTitle = 'INGRESO EN GRACIA';
      statusSubtitle = 'Check-in autorizado temporalmente en periodo de gracia. Se requiere renovación del plan.';
      showDirectPlans = widget.member != null;
    } else if (widget.result == 'denied') {
      bg = colors.danger;
      icon = Icons.cancel_outlined;
      statusTitle = 'ACCESO DENEGADO';
      if (widget.member != null) {
        if (widget.member!.state == 'suspended') {
          statusSubtitle = 'Cuenta de socio suspendida administrativamente.';
        } else if (widget.member!.state == 'inactive') {
          statusSubtitle = 'Membresía en espera de verificación o cuenta inactiva.';
        } else {
          statusSubtitle = 'Membresía vencida. Solicitar regularización o renovación de plan.';
          showDirectPlans = true;
        }
      } else {
        statusSubtitle = 'Socio bloqueado o inactivo.';
        showDirectPlans = false;
      }
    } else {
      // not_found
      bg = colors.textSecondary;
      icon = Icons.search_off_rounded;
      statusTitle = 'DNI INVÁLIDO';
      statusSubtitle = 'DNI inválido - Usuario no registrado en este gimnasio.';
      showDirectPlans = false;
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 88, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  statusTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  statusSubtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (widget.member != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: widget.palette.accent.withValues(alpha: 0.15),
                              child: Text(
                                widget.member!.name.substring(0, widget.member!.name.length >= 2 ? 2 : widget.member!.name.length).toUpperCase(),
                                style: TextStyle(color: widget.palette.accentInk, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.member!.name,
                                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w900, fontSize: 15.5),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'DNI: ${widget.member!.dni}',
                                    style: TextStyle(color: colors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1, color: colors.border),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estado:',
                              style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            StatusPill(
                              label: widget.member!.state == 'active'
                                  ? 'ACTIVO'
                                  : (widget.member!.state == 'grace' ? 'DÍAS DE GRACIA' : 'VENCIDO'),
                              color: widget.member!.state == 'active'
                                  ? colors.success
                                  : (widget.member!.state == 'grace' ? colors.warning : colors.danger),
                              solid: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Plan Actual/Último:',
                              style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.member!.goal.isNotEmpty ? widget.member!.goal : 'Sin Plan',
                              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Vigencia:',
                              style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            if (widget.member!.daysLeft != null)
                              Text(
                                widget.member!.daysLeft! > 0
                                    ? '${widget.member!.daysLeft} días restantes'
                                    : (widget.member!.daysLeft! == 0 ? 'Vence hoy' : 'Vencido hace ${widget.member!.daysLeft!.abs()} días'),
                                style: TextStyle(
                                  color: widget.member!.daysLeft! > 0
                                      ? colors.success
                                      : (widget.member!.daysLeft! == 0 ? colors.warning : colors.danger),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                ),
                              )
                            else
                              Text(
                                'Indeterminada',
                                style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (showDirectPlans) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACCESO DIRECTO / ASIGNAR PLAN',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),
                        ..._directPlans().expand(
                          (plan) => [
                            _buildDirectPlanTile(context, plan.name, plan.price),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Column(
                  children: [
                    if (widget.result == 'not_found' && widget.onCreateNewClient != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: roleFilledPillButtonStyle(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.blue),
                          label: const Text('Crear Nuevo Socio', style: TextStyle(fontWeight: FontWeight.w800)),
                          onPressed: () => widget.onCreateNewClient!(widget.dni),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (widget.result == 'granted') ...[
                      Text(
                        'Regresando al escáner en $_secondsLeft segundos...',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: roleFilledPillButtonStyle(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: widget.onBack,
                          child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        ),
                      ),
                    ] else if (widget.result == 'grace') ...[
                      Text(
                        'Ingreso registrado en gracia. El socio debe regularizar su pago.',
                        style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: roleFilledPillButtonStyle(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: widget.onBack,
                          child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        ),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: roleFilledPillButtonStyle(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.replay_rounded),
                              label: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.w800)),
                              onPressed: widget.onBack,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<MembershipPlan> _directPlans() {
    final activePlans = widget.membershipPlans.where((p) => p.active).toList();
    if (activePlans.isNotEmpty) return activePlans.take(4).toList();
    return const [
      MembershipPlan(id: '', name: 'Plan Mensual Oro', durationDays: 30, price: 150),
      MembershipPlan(id: '', name: 'Plan Mensual Plata', durationDays: 30, price: 120),
      MembershipPlan(id: '', name: 'Plan Trimestral Platinium', durationDays: 90, price: 400),
    ];
  }

  Widget _buildDirectPlanTile(BuildContext context, String name, double price) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13)),
          trailing: Text(
            'S/ $price',
            style: TextStyle(fontWeight: FontWeight.w900, color: widget.palette.accentInk, fontSize: 12),
          ),
          onTap: () => widget.onChargeDirect(widget.dni, planName: name, price: price),
        ),
      ),
    );
  }
}
