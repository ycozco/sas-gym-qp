import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../widgets/app_shell.dart';

class CashierMembershipsPage extends StatefulWidget {
  const CashierMembershipsPage({
    super.key,
    required this.palette,
    required this.state,
    this.prefilledDni,
    this.prefilledPlanName,
    this.prefilledPlanPrice,
    this.onClearPrefilledDni,
    this.onSellPlan,
  });

  final RolePalette palette;
  final GymState state;
  final String? prefilledDni;
  final String? prefilledPlanName;
  final double? prefilledPlanPrice;
  final VoidCallback? onClearPrefilledDni;
  final Function(String dni, {String? planName, double? price})? onSellPlan;

  @override
  State<CashierMembershipsPage> createState() => _CashierMembershipsPageState();
}

class _CashierMembershipsPageState extends State<CashierMembershipsPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.prefilledDni != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.prefilledPlanName != null) {
          // Coming from scanner with a specific plan → find/create member and open assign dialog
          final members = widget.state.members;
          final idx = members.indexWhere((m) => m.dni == widget.prefilledDni);
          if (idx != -1) {
            _showAssignPlanDialog(
              context,
              members[idx],
              defaultPlan: widget.prefilledPlanName,
              defaultPrice: widget.prefilledPlanPrice,
            );
          } else {
            // Member not found — open new member form then assign
            _showAddMemberDialog(context, prefilledDni: widget.prefilledDni);
          }
        } else {
          _showAddMemberDialog(context, prefilledDni: widget.prefilledDni);
        }
        widget.onClearPrefilledDni?.call();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final filteredMembers = widget.state.members
        .where((m) =>
            m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            m.dni.contains(_searchQuery) ||
            m.state.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        RoleHeroHeader(
          palette: widget.palette,
          title: 'Membresías',
          subtitle: 'Busca socios por QR, DNI o Nombre y verifica el estado de su membresía.',
        ),
        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2DDD5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Buscar por QR, DNI o Nombre...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: roleFilledPillButtonStyle(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Registrar', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showAddMemberDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 20),

        const SectionHeader(title: 'Socios Encontrados'),
        if (filteredMembers.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2DDD5)),
            ),
            child: const Center(
              child: Text(
                'No se encontraron socios con esos criterios.',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          Column(
            children: filteredMembers.map((m) {
              Color statusColor;
              String statusText;
              switch (m.state) {
                case 'active':
                  statusColor = Colors.green;
                  statusText = 'Activo';
                  break;
                case 'grace':
                  statusColor = Colors.amber;
                  statusText = 'Gracia';
                  break;
                case 'expired':
                case 'inactive':
                  statusColor = Colors.red;
                  statusText = 'Vencido';
                  break;
                default:
                  statusColor = Colors.grey;
                  statusText = m.state;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2DDD5)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: widget.palette.accent.withValues(alpha: 0.12),
                    child: Text(
                      m.name.substring(0, m.name.length >= 2 ? 2 : m.name.length).toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: widget.palette.accentInk),
                    ),
                  ),
                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text('DNI: ${m.dni} · ${m.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () => _showVerifyMembershipDialog(context, m),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showAddMemberDialog(BuildContext context, {String? prefilledDni}) {
    final dniCtrl = TextEditingController(text: prefilledDni ?? '');
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final goalCtrl = TextEditingController();
    final trainerCtrl = TextEditingController();
    String stateSelect = 'expired';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2DDD5)),
              ),
              title: const Text('Registrar Nuevo Socio', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dniCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'DNI / Documento *'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre Completo *'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Celular'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: goalCtrl,
                      decoration: const InputDecoration(labelText: 'Objetivo (ej: Bajar peso)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: trainerCtrl,
                      decoration: const InputDecoration(labelText: 'Entrenador Asignado'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: stateSelect,
                      decoration: const InputDecoration(labelText: 'Estado Inicial'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Activo')),
                        DropdownMenuItem(value: 'expired', child: Text('Vencido')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => stateSelect = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: roleFilledPillButtonStyle(
                    backgroundColor: widget.palette.accent,
                    foregroundColor: widget.palette.accentInk,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty && dniCtrl.text.isNotEmpty) {
                      final newMember = MemberRecord(
                        dni: dniCtrl.text.trim(),
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        startDate: 'Hoy',
                        goal: goalCtrl.text.trim(),
                        sessions: 0,
                        lastSeen: 'Nunca',
                        state: stateSelect,
                        assignedTrainer: trainerCtrl.text.trim(),
                        paymentHistory: [],
                        physicalMeasurements: {},
                        progressImages: [],
                      );
                      widget.state.addMember(newMember);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nuevo socio registrado con éxito.'), backgroundColor: Color(0xFF00B85C)),
                      );
                    }
                  },
                  child: const Text('Registrar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showVerifyMembershipDialog(BuildContext context, MemberRecord member) {
    showDialog(
      context: context,
      builder: (ctx) {
        Color statusColor;
        String statusText;
        switch (member.state) {
          case 'active':
            statusColor = Colors.green;
            statusText = 'Activo';
            break;
          case 'grace':
            statusColor = Colors.amber;
            statusText = 'Gracia';
            break;
          case 'expired':
          case 'inactive':
            statusColor = Colors.red;
            statusText = 'Vencido';
            break;
          default:
            statusColor = Colors.grey;
            statusText = member.state;
        }

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE2DDD5)),
          ),
          title: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _detailRow('DNI / ID:', member.dni),
                _detailRow('Email:', member.email),
                _detailRow('Teléfono:', member.phone),
                _detailRow('Entrenador:', member.assignedTrainer.isEmpty ? 'Ninguno' : member.assignedTrainer),
                _detailRow('Objetivo:', member.goal),
                const Divider(height: 24, color: Color(0xFFE8E4D9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estado de Membresía:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (member.paymentHistory.isNotEmpty) ...[
                  const Text('Historial de Planes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 6),
                  ...member.paymentHistory.map((pay) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEFECE6)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pay.planName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              Text('${pay.date} · ${pay.method}', style: const TextStyle(color: Colors.grey, fontSize: 10.5)),
                            ],
                          ),
                          Text('S/ ${pay.price}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        ],
                      ),
                    );
                  }),
                ] else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'No registra historial de pagos de membresía.',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: roleFilledPillButtonStyle(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (widget.onSellPlan != null) {
                  widget.onSellPlan!(member.dni);
                } else {
                  _showAssignPlanDialog(context, member);
                }
              },
              child: const Text('Vender Plan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAssignPlanDialog(BuildContext context, MemberRecord member, {String? defaultPlan, double? defaultPrice}) {
    final plans = widget.state.membershipPlans.isNotEmpty
        ? widget.state.membershipPlans.where((p) => p.active).toList()
        : const [
            MembershipPlan(id: '', name: 'Plan Mensual Oro', durationDays: 30, price: 150),
            MembershipPlan(id: '', name: 'Plan Mensual Plata', durationDays: 30, price: 120),
            MembershipPlan(id: '', name: 'Plan Trimestral Platinium', durationDays: 90, price: 400),
            MembershipPlan(id: '', name: 'Pase por un Dia', durationDays: 1, price: 25),
          ];
    MembershipPlan selectedPlan = plans.firstWhere(
      (p) => p.name == defaultPlan,
      orElse: () => plans.first,
    );
    double price = defaultPrice ?? selectedPlan.price;
    String paymentMethod = 'Efectivo';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setPlanState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2DDD5)),
              ),
              title: Text('Asignar Membresía a ${member.name}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedPlan.id.isNotEmpty ? selectedPlan.id : selectedPlan.name,
                    decoration: const InputDecoration(labelText: 'Plan de Membresía'),
                    items: plans.map((p) {
                      final value = p.id.isNotEmpty ? p.id : p.name;
                      return DropdownMenuItem(value: value, child: Text('${p.name} (S/ ${p.price})'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final nextPlan = plans.firstWhere(
                          (p) => (p.id.isNotEmpty ? p.id : p.name) == val,
                          orElse: () => selectedPlan,
                        );
                        setPlanState(() {
                          selectedPlan = nextPlan;
                          price = nextPlan.price;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: const InputDecoration(labelText: 'Método de Pago'),
                    items: const [
                      DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                      DropdownMenuItem(value: 'Yape', child: Text('Yape')),
                      DropdownMenuItem(value: 'Plin', child: Text('Plin')),
                      DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setPlanState(() => paymentMethod = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: roleFilledPillButtonStyle(
                    backgroundColor: widget.palette.accent,
                    foregroundColor: widget.palette.accentInk,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () async {
                    if (widget.state.isBackendMode) {
                      try {
                        final ok = await widget.state.chargePOSBackend(
                          memberDni: member.dni,
                          cartItems: [
                            {'planId': selectedPlan.id, 'name': selectedPlan.name, 'price': price, 'qty': 1, 'icon': 'membership'}
                          ],
                          total: price,
                          paymentMethod: paymentMethod,
                        );
                        if (ok && context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Membresía asignada y cobrada con éxito.'), backgroundColor: Color(0xFF00B85C)),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error al asignar la membresía en el backend.'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    } else {
                      widget.state.chargePOS(
                        memberDni: member.dni,
                        cartItems: [
                          {'planId': selectedPlan.id, 'name': selectedPlan.name, 'price': price, 'qty': 1, 'icon': 'membership'}
                        ],
                        total: price,
                        paymentMethod: paymentMethod,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Membresía asignada exitosamente (Demo).'), backgroundColor: Color(0xFF00B85C)),
                      );
                    }
                  },
                  child: const Text('Confirmar Venta', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _detailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF111111)), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
