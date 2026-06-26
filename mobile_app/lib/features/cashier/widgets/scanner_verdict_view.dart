import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';

class ScannerVerdictView extends StatefulWidget {
  const ScannerVerdictView({
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
  State<ScannerVerdictView> createState() => _ScannerVerdictViewState();
}

class _ScannerVerdictViewState extends State<ScannerVerdictView> {
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
      statusSubtitle = 'Miembro activo y habilitado para entrenar hoy.';
    } else if (widget.result == 'grace') {
      bg = colors.warning;
      icon = Icons.warning_amber_rounded;
      statusTitle = 'INGRESO EN GRACIA';
      statusSubtitle =
          'Habilitado temporalmente. Plan requiere renovación inmediata.';
      showDirectPlans = widget.member != null;
    } else if (widget.result == 'denied') {
      bg = colors.danger;
      icon = Icons.cancel_outlined;
      statusTitle = 'ACCESO DENEGADO';
      if (widget.member != null) {
        if (widget.member!.state == 'suspended') {
          statusSubtitle = 'Cuenta de socio suspendida administrativamente.';
        } else if (widget.member!.state == 'inactive') {
          statusSubtitle =
              'Membresía en espera de verificación o cuenta inactiva.';
        } else {
          statusSubtitle =
              'Membresía vencida. Regulariza el estado de pago del socio.';
          showDirectPlans = true;
        }
      } else {
        statusSubtitle = 'Socio inactivo, suspendido o sin membresía asignada.';
        showDirectPlans = false;
      }
    } else {
      // not_found / error
      bg = colors.textSecondary;
      icon = Icons.search_off_rounded;
      statusTitle = 'SOCIO NO REGISTRADO';
      statusSubtitle =
          'DNI ${widget.dni} no figura en el sistema de este local.';
      showDirectPlans = false;
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Verdict Icon
                Icon(icon, size: 88, color: Colors.white),
                const SizedBox(height: 18),
                // Verdict Title
                Text(
                  statusTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Verdict Subtitle
                Text(
                  statusSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Member Details Card
                if (widget.member != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
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
                              radius: 22,
                              backgroundColor: widget.palette.accent.withValues(
                                alpha: 0.15,
                              ),
                              child: Text(
                                widget.member!.name
                                    .substring(
                                      0,
                                      widget.member!.name.length >= 2
                                          ? 2
                                          : widget.member!.name.length,
                                    )
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: widget.palette.accentInk,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.member!.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: colors.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'DNI: ${widget.member!.dni}',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            StatusPill(
                              label: widget.member!.state == 'active'
                                  ? 'ACTIVO'
                                  : (widget.member!.state == 'grace'
                                        ? 'DÍAS DE GRACIA'
                                        : 'VENCIDO'),
                              color: widget.member!.state == 'active'
                                  ? colors.success
                                  : (widget.member!.state == 'grace'
                                        ? colors.warning
                                        : colors.danger),
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
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.member!.goal.isNotEmpty
                                  ? widget.member!.goal
                                  : 'Sin Plan',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Vigencia:',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.member!.daysLeft != null)
                              Text(
                                widget.member!.daysLeft! > 0
                                    ? '${widget.member!.daysLeft} días restantes'
                                    : (widget.member!.daysLeft! == 0
                                          ? 'Vence hoy'
                                          : 'Vencido hace ${widget.member!.daysLeft!.abs()} días'),
                                style: TextStyle(
                                  color: widget.member!.daysLeft! > 0
                                      ? colors.success
                                      : (widget.member!.daysLeft! == 0
                                            ? colors.warning
                                            : colors.danger),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                ),
                              )
                            else
                              Text(
                                'Indeterminada',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Direct Quick Access Plans
                if (showDirectPlans) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACCESO DIRECTO / VENTA DE PLANES',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.member != null &&
                            widget.member!.goal.isNotEmpty) ...[
                          _buildDirectPlanTile(
                            context,
                            name: widget.member!.goal,
                            price:
                                widget.member!.goal.toLowerCase().contains(
                                  'plata',
                                )
                                ? 120.0
                                : (widget.member!.goal.toLowerCase().contains(
                                            'trimestral',
                                          ) ||
                                          widget.member!.goal
                                              .toLowerCase()
                                              .contains('platinium')
                                      ? 400.0
                                      : 150.0),
                            details: 'Membresía actual a renovar (Sugerida)',
                            isSuggested: true,
                          ),
                          const SizedBox(height: 8),
                        ],
                        ..._directPlans().expand(
                          (plan) => [
                            _buildDirectPlanTile(
                              context,
                              name: plan.name,
                              price: plan.price,
                              details:
                                  plan.description ??
                                  '${plan.durationDays} dias',
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Action Buttons Row
                Column(
                  children: [
                    if (widget.result == 'not_found' &&
                        widget.onCreateNewClient != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: roleFilledPillButtonStyle(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Colors.blue,
                          ),
                          label: const Text(
                            'Crear Nuevo Socio',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          onPressed: () =>
                              widget.onCreateNewClient!(widget.dni),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (widget.result == 'granted') ...[
                      Text(
                        'Regresando a inicio en $_secondsLeft segundos...',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
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
                          child: const Text(
                            'Listo',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ] else if (widget.result == 'grace') ...[
                      Text(
                        'Ingreso registrado en gracia. El socio debe regularizar su pago.',
                        style: TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
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
                          child: const Text(
                            'Listo',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: roleFilledPillButtonStyle(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              icon: const Icon(Icons.replay_rounded),
                              label: const Text(
                                'Reintentar',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
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
      MembershipPlan(
        id: '',
        name: 'Plan Mensual Oro',
        durationDays: 30,
        price: 150,
      ),
      MembershipPlan(
        id: '',
        name: 'Plan Mensual Plata',
        durationDays: 30,
        price: 120,
      ),
      MembershipPlan(
        id: '',
        name: 'Plan Trimestral Platinium',
        durationDays: 90,
        price: 400,
      ),
    ];
  }

  Widget _buildDirectPlanTile(
    BuildContext context, {
    required String name,
    required double price,
    required String details,
    bool isSuggested = false,
  }) {
    final colors = context.sasColors;
    return Container(
      decoration: BoxDecoration(
        color: isSuggested
            ? colors.warning.withValues(alpha: 0.16)
            : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isSuggested
            ? Border.all(color: colors.warning, width: 1.5)
            : Border.all(color: colors.border),
        boxShadow: isSuggested
            ? [
                BoxShadow(
                  color: colors.warning.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: isSuggested
              ? Icon(Icons.star_rounded, color: colors.warning, size: 20)
              : null,
          title: Row(
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  fontSize: 13.5,
                ),
              ),
              if (isSuggested) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SUGERIDO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            details,
            style: TextStyle(
              color: isSuggested ? colors.textPrimary : colors.textSecondary,
              fontSize: 11,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.palette.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'S/ $price',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: widget.palette.accentInk,
                fontSize: 12.5,
              ),
            ),
          ),
          onTap: () =>
              widget.onChargeDirect(widget.dni, planName: name, price: price),
        ),
      ),
    );
  }
}
