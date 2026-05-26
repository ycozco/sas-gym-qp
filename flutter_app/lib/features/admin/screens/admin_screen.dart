import 'package:flutter/material.dart';
import 'package:otp/otp.dart';

import '../../../data/gym_seed.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';
import '../../../core/network/api_client.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentTab = 0;
  final List<Map<String, dynamic>> _historyStack = [];

  // Active Member Search & Filters
  String _memberSearchQuery = '';
  String _memberFilterState = 'all'; // all, active, expired, grace, baja_logica

  // Scanner State
  String _scanDniInput = '';

  // POS/Products Search
  String _productSearchQuery = '';

  // Audit Logs Filters
  String _auditFilterActor = 'all'; // all, Caja, Entrenador, Admin, SuperAdmin
  String _auditSearchQuery = '';

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
    final state = GymStateProvider.of(context);
    final palette = rolePalettes[GymRole.admin]!;

    bool hideNav = false;
    Widget? activeView;

    // Check history stack for active sub-views
    if (_historyStack.isNotEmpty) {
      final top = _historyStack.last;
      final String screen = top['screen'];
      final Map<String, dynamic>? params = top['params'];

      if (screen == 'verdict') {
        hideNav = true;
        final String scanResult = params?['result'] ?? 'denied';
        final MemberRecord? member = params?['member'] as MemberRecord?;
        final String dni = params?['dni'] ?? '';

        activeView = _AdminVerdictView(
          palette: palette,
          result: scanResult,
          member: member,
          dni: dni,
          onBack: _back,
        );
      } else if (screen == 'member_detail') {
        final MemberRecord member = params?['member'] as MemberRecord;
        activeView = _AdminMemberDetailPage(
          palette: palette,
          state: state,
          memberDni: member.dni,
          onBack: _back,
          onEdit: (m) => _go('member_form', {'member': m}),
        );
      } else if (screen == 'member_form') {
        final MemberRecord? member = params?['member'] as MemberRecord?;
        activeView = _AdminMemberFormPage(
          palette: palette,
          state: state,
          member: member,
          onBack: _back,
        );
      } else if (screen == 'payment_approvals') {
        activeView = _AdminPaymentApprovalsPage(
          palette: palette,
          state: state,
          onBack: _back,
        );
      } else if (screen == 'product_inventory') {
        activeView = _AdminProductInventoryPage(
          palette: palette,
          state: state,
          productSearchQuery: _productSearchQuery,
          onProductSearchChanged: (val) => setState(() => _productSearchQuery = val),
          onBack: _back,
          onAddProduct: () => _go('product_form'),
          onEditProduct: (p) => _go('product_form', {'product': p}),
        );
      } else if (screen == 'product_form') {
        final ProductItem? product = params?['product'] as ProductItem?;
        activeView = _AdminProductFormPage(
          palette: palette,
          state: state,
          product: product,
          onBack: _back,
        );
      } else if (screen == 'audit_logs') {
        activeView = _AdminAuditLogsPage(
          palette: palette,
          state: state,
          filterActor: _auditFilterActor,
          searchQuery: _auditSearchQuery,
          onActorChanged: (val) => setState(() => _auditFilterActor = val),
          onSearchChanged: (val) => setState(() => _auditSearchQuery = val),
          onBack: _back,
        );
      } else if (screen == 'observations') {
        activeView = _AdminObservationsPage(
          palette: palette,
          state: state,
          onBack: _back,
        );
      } else if (screen == 'announcement_form') {
        activeView = _AdminAnnouncementFormPage(
          palette: palette,
          state: state,
          onBack: _back,
        );
      } else if (screen == 'settings') {
        activeView = _AdminSettingsPage(
          palette: palette,
          state: state,
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

    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _buildTab(_currentTab, state, palette, key: ValueKey<int>(_currentTab)),
          ),
        ),
        RoleNavBar(
          currentIndex: _currentTab,
          accent: palette.accent,
          accentInk: palette.accentInk,
          onChanged: (index) => setState(() => _currentTab = index),
          items: const [
            RoleNavItem(icon: Icons.dashboard_rounded, label: 'Inicio'),
            RoleNavItem(icon: Icons.people_alt_rounded, label: 'Usuarios'),
            RoleNavItem(icon: Icons.qr_code_scanner_rounded, label: 'Escanear'),
            RoleNavItem(icon: Icons.badge_rounded, label: 'Cajeros'),
            RoleNavItem(icon: Icons.more_horiz_rounded, label: 'Más'),
          ],
        ),
      ],
    );
  }

  Widget _buildTab(int tab, GymState state, RolePalette palette, {Key? key}) {
    switch (tab) {
      case 0:
        return _AdminDashboardPage(
          key: key,
          palette: palette,
          state: state,
          onGoApprovals: () => _go('payment_approvals'),
          onGoCreateMember: () => _go('member_form'),
          onGoSettings: () => _go('settings'),
          onGoAuditLogs: () => _go('audit_logs'),
        );
      case 1:
        return _AdminMembersPage(
          key: key,
          palette: palette,
          state: state,
          searchQuery: _memberSearchQuery,
          filterState: _memberFilterState,
          onSearchChanged: (val) => setState(() => _memberSearchQuery = val),
          onFilterChanged: (val) => setState(() => _memberFilterState = val),
          onSelectMember: (member) => _go('member_detail', {'member': member}),
          onCreateMember: () => _go('member_form'),
        );
      case 2:
        return _AdminScannerPage(
          key: key,
          palette: palette,
          state: state,
          scanInput: _scanDniInput,
          isLaserMoving: true,
          onScanInputChanged: (val) => setState(() => _scanDniInput = val),
          onTriggerVerdict: (result, member, dni) {
            _go('verdict', {'result': result, 'member': member, 'dni': dni});
          },
        );
      case 3:
        return _AdminCashiersPage(
          key: key,
          palette: palette,
          state: state,
        );
      default:
        return _AdminMorePage(
          key: key,
          palette: palette,
          state: state,
          onNavigate: (route) => _go(route),
        );
    }
  }
}

// ============================================================================
// MAIN PAGE VIEWPORT TABS
// ============================================================================

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage({
    super.key,
    required this.palette,
    required this.state,
    required this.onGoApprovals,
    required this.onGoCreateMember,
    required this.onGoSettings,
    required this.onGoAuditLogs,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onGoApprovals;
  final VoidCallback onGoCreateMember;
  final VoidCallback onGoSettings;
  final VoidCallback onGoAuditLogs;

  @override
  Widget build(BuildContext context) {
    // Count pending payments
    int pendingCount = 0;
    for (var m in state.allMembersIncludingSoftDeleted) {
      pendingCount += m.paymentHistory.where((p) => p.state == 'pending').length;
    }

    // Dynamic metrics
    final activeCount = state.members.where((m) => m.state == 'active' || m.state == 'grace').length;
    final totalMembersCount = state.members.length;
    final insideNowCount = state.members.where((m) => m.isActiveInGym).length;

    // Calculate revenue (approved payments)
    double totalRevenue = 0;
    for (var m in state.allMembersIncludingSoftDeleted) {
      for (var p in m.paymentHistory) {
        if (p.state == 'approved') {
          totalRevenue += p.price;
        }
      }
    }

    return ListView(
      key: const PageStorageKey<String>('admin-dashboard'),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        _HeroCard(palette: palette),
        const SizedBox(height: 16),

        if (pendingCount > 0) ...[
          GestureDetector(
            onTap: onGoApprovals,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2C0F14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded, color: Colors.redAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bandeja de Pagos ($pendingCount pendientes)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFF5252)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Hay comprobantes manuales de socios esperando tu validación.',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFFF8A80)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.redAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        Row(
          children: [
            Expanded(
              child: _AdminMetric(
                label: 'Socios Activos',
                value: '$activeCount',
                note: 'Total: $totalMembersCount registrados',
                accent: palette.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AdminMetric(
                label: 'Adentro Ahora',
                value: '$insideNowCount',
                note: 'Check-ins activos',
                accent: const Color(0xFF00B85C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AdminMetric(
                label: 'Recaudado Total',
                value: 'S/ ${totalRevenue.toStringAsFixed(0)}',
                note: 'Planes aprobados',
                accent: const Color(0xFFFF7A1A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AdminMetric(
                label: 'Cuentas Caja',
                value: '${state.cashiers.length}',
                note: '${state.cashiers.where((c) => c.active).length} activas hoy',
                accent: Colors.blueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Acciones Rápidas'),
        Row(
          children: [
            Expanded(
              child: ActionTile(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Crear Socio',
                note: 'Formulario de alta',
                accent: palette.accent,
                onTap: onGoCreateMember,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ActionTile(
                icon: Icons.fact_check_outlined,
                label: 'Auditoría',
                note: 'Bitácora general',
                accent: palette.accent,
                onTap: onGoAuditLogs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ActionTile(
                icon: Icons.settings_rounded,
                label: 'Ajustes',
                note: 'Días de gracia y reglas',
                accent: palette.accent,
                onTap: onGoSettings,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ActionTile(
                icon: Icons.rate_review_rounded,
                label: 'Comprobantes',
                note: 'Bandeja de pagos',
                accent: palette.accent,
                onTap: onGoApprovals,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Resumen de Control'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: const Text(
            'Como administrador, controlas de forma global los cajeros, autorizaciones de dinero, el catálogo de productos y el alta o baja física/lógica de usuarios. Monitorea las acciones en tiempo real mediante la Bitácora de Auditoría.',
            style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _AdminMembersPage extends StatelessWidget {
  const _AdminMembersPage({
    super.key,
    required this.palette,
    required this.state,
    required this.searchQuery,
    required this.filterState,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSelectMember,
    required this.onCreateMember,
  });

  final RolePalette palette;
  final GymState state;
  final String searchQuery;
  final String filterState;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<MemberRecord> onSelectMember;
  final VoidCallback onCreateMember;

  @override
  Widget build(BuildContext context) {
    // Determine which list to filter
    final rawList = filterState == 'baja_logica'
        ? state.allMembersIncludingSoftDeleted.where((m) => m.state == 'baja_logica').toList()
        : state.members;

    // Filter by state and search text
    final filteredMembers = rawList.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(searchQuery.toLowerCase()) || m.dni.contains(searchQuery);
      if (!matchesSearch) return false;

      if (filterState == 'all' || filterState == 'baja_logica') return true;
      return m.state == filterState;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: SectionHeader(title: 'Socios Registrados', action: 'Gestión total')),
              IconButton(
                onPressed: onCreateMember,
                icon: Icon(Icons.add_circle_rounded, color: palette.accent, size: 28),
                tooltip: 'Crear Socio',
              ),
            ],
          ),
          // Search Box
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o DNI...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFF16161A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF232329)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF232329)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todos', 'all'),
                const SizedBox(width: 6),
                _filterChip('Activos', 'active'),
                const SizedBox(width: 6),
                _filterChip('Vencidos', 'expired'),
                const SizedBox(width: 6),
                _filterChip('En Gracia', 'grace'),
                const SizedBox(width: 6),
                _filterChip('Bajas Lógicas', 'baja_logica'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Members List
          Expanded(
            child: filteredMembers.isEmpty
                ? Center(
                    child: Text(
                      'No se encontraron socios.',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final m = filteredMembers[index];
                      Color stateColor = const Color(0xFF00B85C);
                      if (m.state == 'expired') stateColor = const Color(0xFFFF3B30);
                      if (m.state == 'grace') stateColor = const Color(0xFFFFB300);
                      if (m.state == 'baja_logica') stateColor = const Color(0xFFFF7A1A);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => onSelectMember(m),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: _cardDecoration(),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: palette.accent.withValues(alpha: 0.12),
                                  foregroundColor: palette.accent,
                                  child: Text(
                                    m.name.substring(0, 2).toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'DNI: ${m.dni} · Objetivo: ${m.goal}',
                                        style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusPill(
                                  label: m.state == 'baja_logica' ? 'BAJA' : m.state.toUpperCase(),
                                  color: stateColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = filterState == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onFilterChanged(value);
      },
      selectedColor: palette.accent.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: isSelected ? palette.accent : Colors.white60,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 11.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: const Color(0xFF1D1D22),
    );
  }
}

class _AdminScannerPage extends StatefulWidget {
  const _AdminScannerPage({
    super.key,
    required this.palette,
    required this.state,
    required this.scanInput,
    required this.isLaserMoving,
    required this.onScanInputChanged,
    required this.onTriggerVerdict,
  });

  final RolePalette palette;
  final GymState state;
  final String scanInput;
  final bool isLaserMoving;
  final ValueChanged<String> onScanInputChanged;
  final Function(String result, MemberRecord? member, String dni) onTriggerVerdict;

  @override
  State<_AdminScannerPage> createState() => _AdminScannerPageState();
}

class _AdminScannerPageState extends State<_AdminScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('admin-scanner'),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        const SectionHeader(title: 'Control de Asistencia', action: 'Escáner Admin'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              // Scanner Animation box
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.palette.accent, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              size: 130,
                              color: widget.palette.accent.withValues(alpha: 0.35),
                            ),
                          ),
                          // Simulated sweep line
                          AnimatedBuilder(
                            animation: _laserController,
                            builder: (context, child) {
                              return Positioned(
                                top: _laserController.value * 218,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Supervisa ingresos y salidas en tiempo real.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Ingresa un DNI a continuación o pulsa una simulación directa para validar la lógica del validador.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B6B6B), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Search input for DNI
              TextField(
                onChanged: widget.onScanInputChanged,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Digita DNI del Socio (Ej: 12345678)',
                  prefixIcon: const Icon(Icons.badge_rounded),
                  filled: true,
                  fillColor: const Color(0xFF16161A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF232329)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF232329)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.palette.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Check-in and Check-out trigger buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.palette.accent,
                        foregroundColor: widget.palette.accentInk,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Ingreso', style: TextStyle(fontWeight: FontWeight.w800)),
                      onPressed: widget.scanInput.trim().isEmpty ? null : () => _executeCheckIn(widget.scanInput.trim()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.palette.accent,
                        side: BorderSide(color: widget.palette.accent, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Salida', style: TextStyle(fontWeight: FontWeight.w800)),
                      onPressed: widget.scanInput.trim().isEmpty ? null : () => _executeCheckOut(widget.scanInput.trim()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Simulaciones Rápidas (Púlsa para testear)'),
        Column(
          children: widget.state.allMembersIncludingSoftDeleted.map((member) {
            String sub = 'Estado: ${member.state.toUpperCase()}';
            Color pillCol = const Color(0xFF00B85C);
            if (member.state == 'expired') pillCol = const Color(0xFFFF3B30);
            if (member.state == 'grace') pillCol = const Color(0xFFFFB300);
            if (member.state == 'baja_logica') {
              pillCol = const Color(0xFFFF7A1A);
              sub = 'BAJA LÓGICA';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: _cardDecoration(),
                child: ListTile(
                  dense: true,
                  title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('DNI: ${member.dni} · $sub', style: const TextStyle(color: Colors.white60)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusPill(label: member.state.toUpperCase(), color: pillCol),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.login_rounded, color: Colors.blueAccent),
                        onPressed: () => _executeCheckIn(member.dni),
                        tooltip: 'Check-in',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.grey),
                        onPressed: () => _executeCheckOut(member.dni),
                        tooltip: 'Check-out',
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _executeCheckIn(String input) async {
    String dni = input;
    String otpToken = '';
    
    if (input.contains('|')) {
      final parts = input.split('|');
      dni = parts[0];
      otpToken = parts[1];
    } else {
      // Generate a valid TOTP for testing convenience
      final secret = '${dni}_secure_totp_secret_key_2026';
      final time = DateTime.now().millisecondsSinceEpoch;
      try {
        otpToken = OTP.generateTOTPCodeString(
          secret,
          time,
          interval: 30,
          length: 6,
          algorithm: Algorithm.SHA1,
        );
      } catch (e) {
        debugPrint('Error generating simulator TOTP: $e');
      }
    }

    if (widget.state.isBackendMode) {
      final res = await widget.state.verifyAttendanceBackend(dni: dni, otpToken: otpToken);
      final verdict = res['verdict'];
      final member = res['member'] as MemberRecord?;

      String resultStr = 'denied';
      if (verdict == 'GREEN') resultStr = 'granted';
      if (verdict == 'AMBER') resultStr = 'grace';

      widget.onTriggerVerdict(resultStr, member, dni);
    } else {
      final result = widget.state.recordAttendance(dni);
      final member = widget.state.allMembersIncludingSoftDeleted.firstWhere(
        (m) => m.dni == dni,
        orElse: () => MemberRecord(
          dni: '',
          name: '',
          phone: '',
          email: '',
          startDate: '',
          goal: '',
          sessions: 0,
          lastSeen: '',
          state: 'expired',
          assignedTrainer: '',
          paymentHistory: [],
          physicalMeasurements: {},
          progressImages: [],
        ),
      );
      widget.onTriggerVerdict(result, member.dni.isEmpty ? null : member, dni);
    }
  }

  void _executeCheckOut(String dni) {
    final memberIndex = widget.state.allMembersIncludingSoftDeleted.indexWhere((m) => m.dni == dni);
    if (memberIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Socio con DNI $dni no registrado.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    final member = widget.state.allMembersIncludingSoftDeleted[memberIndex];
    widget.state.checkoutMember(dni);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Salida registrada con éxito para ${member.name}.'),
        backgroundColor: const Color(0xFF00B85C),
      ),
    );
  }
}

class _AdminCashiersPage extends StatelessWidget {
  const _AdminCashiersPage({
    super.key,
    required this.palette,
    required this.state,
  });

  final RolePalette palette;
  final GymState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('admin-cashiers'),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(child: SectionHeader(title: 'Cuentas de Caja', action: 'Permisos en tiempo real')),
            IconButton(
              icon: Icon(Icons.person_add_rounded, color: palette.accent, size: 26),
              onPressed: () => _showAddCashierDialog(context),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: const Text(
            'Habilita o suspende cuentas de caja al instante, y selecciona individualmente qué módulos tienen permitido visualizar en el rol limitado.',
            style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: state.cashiers.map((cashier) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: palette.accent.withValues(alpha: 0.12),
                          foregroundColor: palette.accent,
                          child: Text(
                            cashier.name.substring(0, 2).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cashier.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Horario: ${cashier.shift}',
                                style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        // Cashier Active Switch
                        Switch(
                          value: cashier.active,
                          activeThumbColor: const Color(0xFF00B85C),
                          inactiveTrackColor: Colors.grey.shade800,
                          onChanged: (val) => state.toggleCashierActive(cashier.name),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFF232329)),
                    const Text(
                      'Módulos y Permisos Habilitados:',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    // Permissions Choice list
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        'Cobros',
                        'Asistencia',
                        'Ventas',
                        'Productos',
                        'Usuarios',
                        'Log lectura',
                      ].map((permission) {
                        final hasIt = cashier.permissions.contains(permission);
                        return FilterChip(
                          label: Text(permission, style: TextStyle(fontSize: 10.5, fontWeight: hasIt ? FontWeight.w800 : FontWeight.w500)),
                          selected: hasIt,
                          selectedColor: palette.accent.withValues(alpha: 0.16),
                          checkmarkColor: palette.accent,
                          labelStyle: TextStyle(color: hasIt ? palette.accent : Colors.white60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: hasIt ? palette.accent : const Color(0xFF2E2E38)),
                          backgroundColor: const Color(0xFF1D1D22),
                          onSelected: (selected) {
                            state.toggleCashierPermission(cashier.name, permission);
                          },
                        );
                      }).toList(),
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

  void _showAddCashierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final shiftCtrl = TextEditingController(text: '08:00 - 16:00');
    final List<String> permissions = ['Cobros', 'Asistencia'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16161A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Registrar Cajero', style: TextStyle(fontWeight: FontWeight.w900)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: shiftCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Turno de Horas',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Permisos Iniciales:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: ['Cobros', 'Asistencia', 'Ventas', 'Productos', 'Usuarios', 'Log lectura'].map((perm) {
                        final hasIt = permissions.contains(perm);
                        return ChoiceChip(
                          label: Text(perm, style: const TextStyle(fontSize: 11)),
                          selected: hasIt,
                          selectedColor: palette.accent.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: hasIt ? palette.accent : Colors.white60,
                            fontWeight: hasIt ? FontWeight.w800 : FontWeight.w500,
                          ),
                          backgroundColor: const Color(0xFF1D1D22),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                permissions.add(perm);
                              } else {
                                permissions.remove(perm);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.accentInk,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    // Add new cashier to state
                    state.cashiers.add(
                      CashierAccount(
                        name: nameCtrl.text.trim(),
                        shift: shiftCtrl.text.trim(),
                        permissions: permissions,
                        active: true,
                      ),
                    );
                    state.updateGymSettings(state.graceDays, state.alertDays); // Forces notifyListeners
                    Navigator.pop(context);
                  },
                  child: const Text('Crear', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AdminMorePage extends StatelessWidget {
  const _AdminMorePage({
    super.key,
    required this.palette,
    required this.state,
    required this.onNavigate,
  });

  final RolePalette palette;
  final GymState state;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('admin-more'),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        const SectionHeader(title: 'Módulos Administrativos', action: 'Más opciones'),
        _menuItem(
          icon: Icons.rate_review_rounded,
          title: 'Bandeja de Pagos Comprobante',
          subtitle: 'Aprobar o rechazar pagos manuales de socios',
          color: const Color(0xFF7A5AE0),
          onTap: () => onNavigate('payment_approvals'),
        ),
        _menuItem(
          icon: Icons.inventory_2_outlined,
          title: 'Inventario de Productos',
          subtitle: 'CRUD completo y eliminación definitiva',
          color: const Color(0xFFFF7A1A),
          onTap: () => onNavigate('product_inventory'),
        ),
        _menuItem(
          icon: Icons.fact_check_outlined,
          title: 'Bitácora de Auditoría',
          subtitle: 'Logs detallados con filtros por rol',
          color: const Color(0xFF0066FF),
          onTap: () => onNavigate('audit_logs'),
        ),
        _menuItem(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Buzón de Observaciones',
          subtitle: 'Reclamos y sugerencias de los socios',
          color: Colors.blueGrey,
          onTap: () => onNavigate('observations'),
        ),
        _menuItem(
          icon: Icons.campaign_rounded,
          title: 'Publicar Anuncio',
          subtitle: 'Crear avisos generales para el inicio del socio',
          color: const Color(0xFF00B85C),
          onTap: () => onNavigate('announcement_form'),
        ),
        _menuItem(
          icon: Icons.tune_rounded,
          title: 'Ajustes del Gimnasio',
          subtitle: 'Días de gracia, tiempos de alerta y reglas de negocio',
          color: Colors.brown,
          onTap: () => onNavigate('settings'),
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: Colors.white60, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SUB-VIEWS (ON THE ROUTING HISTORY STACK)
// ============================================================================

/// 1. Member Detail View
class _AdminMemberDetailPage extends StatelessWidget {
  const _AdminMemberDetailPage({
    required this.palette,
    required this.state,
    required this.memberDni,
    required this.onBack,
    required this.onEdit,
  });

  final RolePalette palette;
  final GymState state;
  final String memberDni;
  final VoidCallback onBack;
  final ValueChanged<MemberRecord> onEdit;

  @override
  Widget build(BuildContext context) {
    // Find member by DNI
    final index = state.allMembersIncludingSoftDeleted.indexWhere((m) => m.dni == memberDni);
    if (index == -1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Socio no encontrado.'),
            ElevatedButton(onPressed: onBack, child: const Text('Volver')),
          ],
        ),
      );
    }
    final member = state.allMembersIncludingSoftDeleted[index];

    Color statusColor = const Color(0xFF00B85C);
    if (member.state == 'expired') statusColor = const Color(0xFFFF3B30);
    if (member.state == 'grace') statusColor = const Color(0xFFFFB300);
    if (member.state == 'baja_logica') statusColor = const Color(0xFFFF7A1A);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: onBack),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => onEdit(member),
            tooltip: 'Editar Datos',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // Member Profile Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: palette.accent.withValues(alpha: 0.12),
                  child: Text(
                    member.name.substring(0, 2).toUpperCase(),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: palette.accent),
                  ),
                ),
                const SizedBox(height: 14),
                Text(member.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatusPill(label: member.state == 'baja_logica' ? 'BAJA LÓGICA' : member.state.toUpperCase(), color: statusColor),
                    if (member.isActiveInGym) ...[
                      const SizedBox(width: 8),
                      const StatusPill(label: 'ADENTRO NOW', color: Color(0xFF00B85C), solid: true),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                _rowDetail(Icons.badge_rounded, 'DNI', member.dni),
                _rowDetail(Icons.phone_rounded, 'Celular', member.phone),
                _rowDetail(Icons.email_rounded, 'Correo', member.email),
                _rowDetail(Icons.calendar_today_rounded, 'Inicio', member.startDate),
                _rowDetail(Icons.sports_gymnastics_rounded, 'Objetivo', member.goal),
                _rowDetail(Icons.person_pin_rounded, 'Entrenador', member.assignedTrainer),
                _rowDetail(Icons.insights_rounded, 'Sesiones asistidas', '${member.sessions} asistencias'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Physical Measurements
          const SectionHeader(title: 'Medidas Antropométricas'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: member.physicalMeasurements.isEmpty
                ? const Text('Sin medidas logueadas actualmente.', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))
                : Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: member.physicalMeasurements.entries.map((entry) {
                      return Chip(
                        label: Text('${entry.key.toUpperCase()}: ${entry.value} kg/cm', style: const TextStyle(color: Colors.white70)),
                        backgroundColor: const Color(0xFF1D1D22),
                        side: const BorderSide(color: Color(0xFF2E2E38)),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          // Billing logs / Actions
          const SectionHeader(title: 'Acciones de Control'),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: member.state == 'baja_logica' ? const Color(0xFF00B85C) : const Color(0xFFFF7A1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(member.state == 'baja_logica' ? Icons.restore_rounded : Icons.delete_sweep_rounded),
                  label: Text(
                    member.state == 'baja_logica' ? 'Restaurar Socio' : 'Dar de Baja Lógica',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    state.toggleMemberLogicDelete(member.dni);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          member.state == 'baja_logica'
                              ? 'Socio restaurado.'
                              : 'Baja lógica efectuada con éxito.',
                        ),
                        backgroundColor: member.state == 'baja_logica' ? const Color(0xFF00B85C) : const Color(0xFFFF7A1A),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Payment History List
          const SectionHeader(title: 'Historial de Pagos / Comprobantes'),
          member.paymentHistory.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: const Text('Sin historial de pagos registrado.', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                )
              : Column(
                  children: member.paymentHistory.map((p) {
                    Color payCol = const Color(0xFF00B85C);
                    if (p.state == 'pending') payCol = const Color(0xFFFFB300);
                    if (p.state == 'rejected') payCol = const Color(0xFFFF3B30);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: _cardDecoration(),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_rounded, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.planName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                  const SizedBox(height: 3),
                                  Text('${p.date} · Metodo: ${p.method}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('S/ ${p.price}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                StatusPill(label: p.state.toUpperCase(), color: payCol),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _rowDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.accent),
          const SizedBox(width: 10),
          Text('$label:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? 'Ninguno' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Member Form Page (Add / Edit)
class _AdminMemberFormPage extends StatefulWidget {
  const _AdminMemberFormPage({
    required this.palette,
    required this.state,
    this.member,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final MemberRecord? member;
  final VoidCallback onBack;

  @override
  State<_AdminMemberFormPage> createState() => _AdminMemberFormPageState();
}

class _AdminMemberFormPageState extends State<_AdminMemberFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dniController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _goalController;
  late TextEditingController _trainerController;
  late String _stateSelect;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _nameController = TextEditingController(text: m?.name ?? '');
    _dniController = TextEditingController(text: m?.dni ?? '');
    _phoneController = TextEditingController(text: m?.phone ?? '');
    _emailController = TextEditingController(text: m?.email ?? '');
    _goalController = TextEditingController(text: m?.goal ?? 'Hipertrofia');
    _trainerController = TextEditingController(text: m?.assignedTrainer ?? 'Carlos M.');
    _stateSelect = m?.state ?? 'active';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.member != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Socio' : 'Crear Nuevo Socio', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: widget.onBack),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre Completo *', prefixIcon: Icon(Icons.person)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nombre es obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dniController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'DNI / Documento *', prefixIcon: Icon(Icons.badge)),
                    enabled: !isEdit, // Cannot edit DNI key
                    validator: (v) => v == null || v.trim().length < 8 ? 'DNI inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono de Contacto', prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _goalController,
                    decoration: const InputDecoration(labelText: 'Objetivo Principal (Ej: Hipertrofia)', prefixIcon: Icon(Icons.sports_gymnastics)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _trainerController,
                    decoration: const InputDecoration(labelText: 'Entrenador Asignado', prefixIcon: Icon(Icons.person_pin)),
                  ),
                  const SizedBox(height: 16),
                  // Dropdown for State
                  DropdownButtonFormField<String>(
                    initialValue: _stateSelect,
                    decoration: const InputDecoration(labelText: 'Estado de Membresía', prefixIcon: Icon(Icons.history)),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Activo (Habilitado)')),
                      DropdownMenuItem(value: 'expired', child: Text('Vencido (Denegado)')),
                      DropdownMenuItem(value: 'grace', child: Text('Gracia (1 día)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _stateSelect = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saveForm,
              child: Text(isEdit ? 'Guardar Cambios' : 'Registrar Socio', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.member != null) {
      // Edit mode
      final original = widget.member!;
      final updated = original.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        goal: _goalController.text.trim(),
        assignedTrainer: _trainerController.text.trim(),
        state: _stateSelect,
      );
      widget.state.updateMember(original.dni, updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Socio actualizado correctamente.'), backgroundColor: Color(0xFF00B85C)),
      );
    } else {
      // Create mode
      final newMember = MemberRecord(
        dni: _dniController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        startDate: 'Hoy',
        goal: _goalController.text.trim(),
        sessions: 0,
        lastSeen: 'Nunca',
        state: _stateSelect,
        assignedTrainer: _trainerController.text.trim(),
        paymentHistory: [],
        physicalMeasurements: {},
        progressImages: [],
      );
      widget.state.addMember(newMember);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nuevo socio registrado con éxito.'), backgroundColor: Color(0xFF00B85C)),
      );
    }

    widget.onBack();
  }
}

class _AdminPaymentApprovalsPage extends StatefulWidget {
  const _AdminPaymentApprovalsPage({
    required this.palette,
    required this.state,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onBack;

  @override
  State<_AdminPaymentApprovalsPage> createState() => _AdminPaymentApprovalsPageState();
}

class _AdminPaymentApprovalsPageState extends State<_AdminPaymentApprovalsPage> {
  List<Map<String, dynamic>> _pendingPayments = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingPayments();
  }

  Future<void> _loadPendingPayments() async {
    if (!widget.state.isBackendMode) return;
    setState(() => _loading = true);
    final list = await widget.state.getPendingPaymentsBackend();
    if (mounted) {
      setState(() {
        _pendingPayments = list;
        _loading = false;
      });
    }
  }

  String _getReceiptUrl(String filename) {
    if (filename.startsWith('http')) return filename;
    final path = filename.startsWith('/uploads') ? filename : '/uploads/receipts/$filename';
    final baseUrl = ApiClient().dio.options.baseUrl;
    final host = baseUrl.replaceAll('/api/v1', '');
    return '$host$path';
  }

  @override
  Widget build(BuildContext context) {
    // Generate list of pending payments
    List<Map<String, dynamic>> pendingList = [];
    if (widget.state.isBackendMode) {
      for (var item in _pendingPayments) {
        final membership = item['membership'] ?? {};
        final user = membership['user'] ?? {};
        
        pendingList.add({
          'paymentId': item['id'],
          'name': user['nombre_completo'] ?? 'Socio',
          'dni': user['dni'] ?? '',
          'planName': membership['plan_nombre'] ?? 'Membresía',
          'price': (item['monto'] as num?)?.toDouble() ?? 0.0,
          'date': item['timestamp']?.toString().split('T')[0] ?? 'Hoy',
          'method': item['metodo']?.toString() ?? 'Efectivo',
          'receiptUrl': item['comprobante_url'] ?? '',
        });
      }
    } else {
      // In demo mode, we just build the list from memory
      for (var m in widget.state.allMembersIncludingSoftDeleted) {
        for (var p in m.paymentHistory) {
          if (p.state == 'pending') {
            pendingList.add({
              'paymentId': p.id,
              'name': m.name,
              'dni': m.dni,
              'planName': p.planName,
              'price': p.price,
              'date': p.date,
              'method': p.method,
              'receiptUrl': p.receiptUrl,
            });
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Bandeja de Aprobaciones', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: widget.onBack),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.state.isBackendMode)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadPendingPayments,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : pendingList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Colors.grey.shade400, size: 64),
                      const SizedBox(height: 16),
                      const Text('¡Todo al día!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.grey)),
                      const SizedBox(height: 6),
                      const Text('No hay comprobantes de pago pendientes.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: pendingList.length,
                  itemBuilder: (context, index) {
                    final item = pendingList[index];
                    final String paymentId = item['paymentId'];
                    final String name = item['name'];
                    final String dni = item['dni'];
                    final String planName = item['planName'];
                    final double price = item['price'];
                    final String date = item['date'];
                    final String method = item['method'];
                    final String receiptUrl = item['receiptUrl'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: widget.palette.accent.withValues(alpha: 0.1),
                                  foregroundColor: widget.palette.accent,
                                  child: const Icon(Icons.person),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                      const SizedBox(height: 3),
                                      Text('DNI: $dni', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF2C0F14), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('PENDIENTE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: Color(0xFF232329)),
                            _rowItem('Plan solicitado:', planName),
                            _rowItem('Importe a pagar:', 'S/ $price'),
                            _rowItem('Fecha envío:', date),
                            _rowItem('Método registrado:', method),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _showReceiptPreview(context, receiptUrl, price, name),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D1D22),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF2D2D37)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.image_outlined, color: Colors.grey),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        receiptUrl.split('/').last.isEmpty ? 'comprobante.jpg' : receiptUrl.split('/').last,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                    const Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(color: Colors.redAccent),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      if (widget.state.isBackendMode) {
                                        final ok = await widget.state.resolvePaymentBackend(
                                          paymentId: paymentId,
                                          status: 'REJECTED',
                                          comments: 'Comprobante inválido o ilegible.',
                                        );
                                        if (ok) {
                                          messenger.showSnackBar(
                                            const SnackBar(content: Text('Pago rechazado en el servidor.'), backgroundColor: Colors.redAccent),
                                          );
                                          _loadPendingPayments();
                                        }
                                      } else {
                                        widget.state.rejectManualPayment(dni, paymentId);
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text('Pago rechazado (Modo Demo).'), backgroundColor: Colors.redAccent),
                                        );
                                      }
                                    },
                                    child: const Text('Rechazar', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00B85C),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      if (widget.state.isBackendMode) {
                                        final ok = await widget.state.resolvePaymentBackend(
                                          paymentId: paymentId,
                                          status: 'APPROVED',
                                          comments: 'Aprobado por administración.',
                                        );
                                        if (ok) {
                                          messenger.showSnackBar(
                                            const SnackBar(content: Text('Pago aprobado. Membresía del socio activada.'), backgroundColor: Color(0xFF00B85C)),
                                          );
                                          _loadPendingPayments();
                                        }
                                      } else {
                                        widget.state.approveManualPayment(dni, paymentId);
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text('Pago aprobado. Socio activado (Modo Demo).'), backgroundColor: Color(0xFF00B85C)),
                                        );
                                      }
                                    },
                                    child: const Text('Aprobar e Iniciar', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
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

  Widget _rowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showReceiptPreview(BuildContext context, String filename, double price, String memberName) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF16161A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Comprobante de Depósito', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.state.isBackendMode && filename.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 320,
                      color: const Color(0xFF1D1D22),
                      child: Image.network(
                        _getReceiptUrl(filename),
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Center(
                          child: Text(
                            'Error al cargar imagen del comprobante.\nMostrando plantilla simulada.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 320,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1D22),
                      border: Border.all(color: const Color(0xFF2E2E38)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                        const SizedBox(height: 14),
                        const Text('TRANSFERENCIA EXITOSA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Text('S/ ${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF2E2E38)),
                        const SizedBox(height: 10),
                        const _ReceiptField('Destinatario', 'SaaS GYM S.A.C.'),
                        const _ReceiptField('Operación', '784918239'),
                        const _ReceiptField('Fecha y hora', 'Reciente'),
                        _ReceiptField('Referencia', 'Socio: $memberName'),
                        const Spacer(),
                        Text('Archivo: ${filename.split('/').last}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReceiptField extends StatelessWidget {
  const _ReceiptField(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// 4. Product Inventory CRUD Page
class _AdminProductInventoryPage extends StatelessWidget {
  const _AdminProductInventoryPage({
    required this.palette,
    required this.state,
    required this.productSearchQuery,
    required this.onProductSearchChanged,
    required this.onBack,
    required this.onAddProduct,
    required this.onEditProduct,
  });

  final RolePalette palette;
  final GymState state;
  final String productSearchQuery;
  final ValueChanged<String> onProductSearchChanged;
  final VoidCallback onBack;
  final VoidCallback onAddProduct;
  final ValueChanged<ProductItem> onEditProduct;

  @override
  Widget build(BuildContext context) {
    final filteredProducts = state.products.where((p) {
      return p.name.toLowerCase().contains(productSearchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(productSearchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Inventario de Productos', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: onBack),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: onAddProduct,
            tooltip: 'Nuevo Producto',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: onProductSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('Sin productos en el catálogo.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: _cardDecoration(),
                          child: Row(
                            children: [
                              Text(p.icon, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    Text('${p.category} · Stock: ${p.stock}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('S/ ${p.price}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                                        onPressed: () => onEditProduct(p),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                                        onPressed: () => _confirmPhysicalDelete(context, p.name),
                                        tooltip: 'Eliminar Físicamente',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmPhysicalDelete(BuildContext context, String productName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('¿Eliminar Físicamente?', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Text('Esta acción borrará definitivamente "$productName" del inventario. Esta operación no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                state.deleteProductPhysical(productName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Producto eliminado definitivamente.'), backgroundColor: Colors.redAccent),
                );
              },
              child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

/// 5. Product Form (Add / Edit)
class _AdminProductFormPage extends StatefulWidget {
  const _AdminProductFormPage({
    required this.palette,
    required this.state,
    this.product,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final ProductItem? product;
  final VoidCallback onBack;

  @override
  State<_AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<_AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _iconController;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _categoryController = TextEditingController(text: p?.category ?? 'Suplementos');
    _priceController = TextEditingController(text: p?.price.toString() ?? '10.0');
    _stockController = TextEditingController(text: p?.stock.toString() ?? '50');
    _iconController = TextEditingController(text: p?.icon ?? '📦');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Producto' : 'Crear Producto', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: widget.onBack),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre del Producto *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nombre es requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Categoría (Ej: Bebidas) *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Categoría es requerida' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio (S/) *'),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Precio inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock Inicial *'),
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Stock inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _iconController,
                    decoration: const InputDecoration(labelText: 'Emoji Identificador (Ej: 💧)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saveProduct,
              child: Text(isEdit ? 'Guardar Cambios' : 'Crear Producto', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final cat = _categoryController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final stock = int.parse(_stockController.text.trim());
    final icon = _iconController.text.trim().isEmpty ? '📦' : _iconController.text.trim();

    final newProd = ProductItem(
      name: name,
      category: cat,
      price: price,
      stock: stock,
      icon: icon,
    );

    if (widget.product != null) {
      widget.state.updateProduct(widget.product!.name, newProd);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado correctamente.'), backgroundColor: Color(0xFF00B85C)),
      );
    } else {
      widget.state.addProduct(newProd);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto añadido al inventario.'), backgroundColor: Color(0xFF00B85C)),
      );
    }

    widget.onBack();
  }
}

/// 6. Global Audit Logs Page
class _AdminAuditLogsPage extends StatelessWidget {
  const _AdminAuditLogsPage({
    required this.palette,
    required this.state,
    required this.filterActor,
    required this.searchQuery,
    required this.onActorChanged,
    required this.onSearchChanged,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final String filterActor;
  final String searchQuery;
  final ValueChanged<String> onActorChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final filteredLogs = state.auditLogs.where((log) {
      final matchesSearch = log.action.toLowerCase().contains(searchQuery.toLowerCase()) ||
          log.detail.toLowerCase().contains(searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (filterActor == 'all') return true;
      return log.actor.toLowerCase().contains(filterActor.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Bitácora de Auditoría', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: onBack),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Filtrar por acción o detalle...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFF16161A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF232329)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF232329)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: palette.accent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _actorChip('Todos', 'all'),
                      const SizedBox(width: 6),
                      _actorChip('Caja', 'Caja'),
                      const SizedBox(width: 6),
                      _actorChip('Entrenador', 'Trainer'),
                      const SizedBox(width: 6),
                      _actorChip('Admin', 'Admin'),
                      const SizedBox(width: 6),
                      _actorChip('SuperAdmin', 'SuperAdmin'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(child: Text('No hay logs coincidentes.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LogTile(
                          icon: log.action.contains('Cobró') || log.action.contains('Venta')
                              ? Icons.point_of_sale_rounded
                              : log.action.contains('Creó') || log.action.contains('Registró')
                                  ? Icons.person_add_alt_1_rounded
                                  : log.action.contains('Baja') || log.action.contains('Eliminó')
                                      ? Icons.delete_outline_rounded
                                      : Icons.list_alt_rounded,
                          title: log.action,
                          detail: '${log.detail} · ${log.actor}',
                          time: log.time,
                          color: log.color,
                          locked: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _actorChip(String label, String value) {
    final isSelected = filterActor == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onActorChanged(value);
      },
      selectedColor: palette.accent.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: isSelected ? palette.accent : Colors.white60,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: const Color(0xFF1D1D22),
    );
  }
}

/// 7. Observations View Page
class _AdminObservationsPage extends StatelessWidget {
  const _AdminObservationsPage({
    required this.palette,
    required this.state,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Buzón de Observaciones', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: onBack),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: state.observations.isEmpty
          ? const Center(child: Text('No hay quejas o sugerencias recibidas.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: state.observations.length,
              itemBuilder: (context, index) {
                final obs = state.observations[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(obs.category.toUpperCase(), style: TextStyle(color: palette.accent, fontWeight: FontWeight.bold, fontSize: 11.5)),
                            Text(obs.date, style: const TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          obs.description,
                          style: const TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Reportado por: ${obs.memberName}', style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w600)),
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
}

/// 8. Publish Announcement Form
class _AdminAnnouncementFormPage extends StatefulWidget {
  const _AdminAnnouncementFormPage({
    required this.palette,
    required this.state,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onBack;

  @override
  State<_AdminAnnouncementFormPage> createState() => _AdminAnnouncementFormPageState();
}

class _AdminAnnouncementFormPageState extends State<_AdminAnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _tag = 'AVISO'; // AVISO, EVENTO, ALERTA
  final _titleCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Publicar Anuncio', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: widget.onBack),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _tag,
                    decoration: const InputDecoration(labelText: 'Etiqueta de importancia'),
                    items: const [
                      DropdownMenuItem(value: 'AVISO', child: Text('Aviso General')),
                      DropdownMenuItem(value: 'EVENTO', child: Text('Evento / Invitación')),
                      DropdownMenuItem(value: 'ALERTA', child: Text('Alerta Urgente')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _tag = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título del Anuncio *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Título es requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _detailCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Contenido / Detalle *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Contenido es requerido' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                widget.state.addAnnouncement(_tag, _titleCtrl.text.trim(), _detailCtrl.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Anuncio publicado en el feed de socios.'), backgroundColor: Color(0xFF00B85C)),
                );
                widget.onBack();
              },
              child: const Text('Publicar Anuncio', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 9. Gym Rules / Settings View
class _AdminSettingsPage extends StatefulWidget {
  const _AdminSettingsPage({
    required this.palette,
    required this.state,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onBack;

  @override
  State<_AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<_AdminSettingsPage> {
  late int _graceDays;
  late int _alertDays;

  @override
  void initState() {
    super.initState();
    _graceDays = widget.state.graceDays;
    _alertDays = widget.state.alertDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Ajustes del Gimnasio', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: widget.onBack),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reglas de Control de Membresía',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Afecta directamente el veredicto del escáner y notificaciones de los socios.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Grace days slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Días de Gracia del Gimnasio:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$_graceDays días', style: TextStyle(color: widget.palette.accent, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Periodo extra posterior al vencimiento donde se permite el check-in (Veredicto Amarillo).', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Slider(
                  value: _graceDays.toDouble(),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: '$_graceDays',
                  onChanged: (val) => setState(() => _graceDays = val.round()),
                ),

                const SizedBox(height: 18),

                // Warning days slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Alerta de Vencimiento Próximo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$_alertDays días', style: TextStyle(color: widget.palette.accent, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Días antes del vencimiento para notificar al socio en su dashboard de inicio.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Slider(
                  value: _alertDays.toDouble(),
                  min: 1,
                  max: 15,
                  divisions: 14,
                  label: '$_alertDays',
                  onChanged: (val) => setState(() => _alertDays = val.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.palette.accent,
              foregroundColor: widget.palette.accentInk,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              widget.state.updateGymSettings(_graceDays, _alertDays);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ajustes del gimnasio guardados reactivamente.'), backgroundColor: Color(0xFF00B85C)),
              );
              widget.onBack();
            },
            child: const Text('Guardar Ajustes', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

/// 10. Shared Scanner Verdict Screen (Full Page Screen)
class _AdminVerdictView extends StatelessWidget {
  const _AdminVerdictView({
    required this.palette,
    required this.result,
    required this.member,
    required this.dni,
    required this.onBack,
  });

  final RolePalette palette;
  final String result;
  final MemberRecord? member;
  final String dni;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    Color bg;
    IconData icon;
    String statusTitle;
    String statusSubtitle;

    if (result == 'granted') {
      bg = const Color(0xFF00B85C); // Green
      icon = Icons.check_circle_outline_rounded;
      statusTitle = 'ACCESO CONCEDIDO';
      statusSubtitle = 'Socio activo. El registro de asistencia fue grabado exitosamente.';
    } else if (result == 'grace') {
      bg = const Color(0xFFFFB300); // Yellow
      icon = Icons.warning_amber_rounded;
      statusTitle = 'INGRESO EN GRACIA';
      statusSubtitle = 'Check-in autorizado temporalmente en periodo de gracia. Se requiere renovación del plan.';
    } else if (result == 'denied') {
      bg = const Color(0xFFFF3B30); // Red
      icon = Icons.cancel_outlined;
      statusTitle = 'ACCESO DENEGADO';
      statusSubtitle = member != null
          ? 'Membresía vencida. Solicitar regularización o renovación de plan.'
          : 'Socio bloqueado o inactivo.';
    } else {
      // not_found
      bg = const Color(0xFF5C5C5C); // Grey
      icon = Icons.search_off_rounded;
      statusTitle = 'DNI NO REGISTRADO';
      statusSubtitle = 'El documento $dni no se encuentra en el sistema de socios.';
    }

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 96, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                statusTitle,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                statusSubtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14.5, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              if (member != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(
                          member!.name.substring(0, 2).toUpperCase(),
                          style: TextStyle(color: bg, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member!.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'DNI: ${member!.dni} · Plan: ${member!.paymentHistory.isEmpty ? "Ninguno" : member!.paymentHistory.last.planName}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: onBack,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET HELPER IMPLEMENTATIONS
// ============================================================================

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.palette});

  final RolePalette palette;

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final user = state.currentUser;
    final String name = user != null ? user.nombreCompleto.split(' ').first : 'Sandra';

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
          const StatusPill(label: 'ADMINISTRADOR', color: Color(0xFF7A5AE0), solid: true),
          const SizedBox(height: 18),
          Text(
            'Hola, $name',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.7, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Gestión total de caja, aprobación de comprobantes, inventario de productos y permisos de acceso.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _AdminMetric extends StatelessWidget {
  const _AdminMetric({
    required this.label,
    required this.value,
    required this.note,
    required this.accent,
  });

  final String label;
  final String value;
  final String note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.6, color: accent),
          ),
          const SizedBox(height: 6),
          Text(note, style: const TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: const Color(0xFF16161A),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFF232329), width: 1.0),
  );
}
