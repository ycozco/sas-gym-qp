import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:dio/dio.dart';
import '../../../data/gym_seed.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  int _currentTab = 0;
  final List<Map<String, dynamic>> _historyStack = [];

  // POS State
  String? _selectedMemberDni;
  final List<Map<String, dynamic>> _cartItems = [];
  double _cashPaid = 0;
  String _paymentMethod = 'Efectivo'; // Efectivo, Yape, Plin, Tarjeta

  // Scanner Simulator State
  String _scanDniInput = '';

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

  // Helper to switch tab and auto-populate POS for scanner denied redirection
  void _redirectScannerToPOS(String memberDni) {
    setState(() {
      _historyStack.clear();
      _currentTab = 2; // POS tab
      _selectedMemberDni = memberDni;
      _cartItems.clear();
      // Auto-add default membership plan
      _cartItems.add({
        'name': 'Plan Mensual Oro',
        'price': 150.0,
        'qty': 1,
        'icon': '🏋️',
      });
      _cashPaid = 150.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final palette = rolePalettes[GymRole.cashier]!;

    bool hideNav = false;
    Widget? activeView;

    if (_historyStack.isNotEmpty) {
      final top = _historyStack.last;
      final String screen = top['screen'];
      final Map<String, dynamic>? params = top['params'];

      if (screen == 'verdict') {
        hideNav = true;
        final String scanResult = params?['result'] ?? 'denied';
        final MemberRecord? member = params?['member'] as MemberRecord?;
        final String dni = params?['dni'] ?? '';

        activeView = _ScannerVerdictView(
          palette: palette,
          result: scanResult,
          member: member,
          dni: dni,
          onBack: _back,
          onChargeDirect: (memberDni) {
            _redirectScannerToPOS(memberDni);
          },
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildTab(_currentTab, state, palette, key: ValueKey<int>(_currentTab)),
            ),
          ),
          RoleNavBar(
            currentIndex: _currentTab,
            accent: palette.accent,
            accentInk: palette.accentInk,
            onChanged: (index) => setState(() => _currentTab = index),
            items: const [
              RoleNavItem(icon: Icons.home_rounded, label: 'Inicio'),
              RoleNavItem(icon: Icons.qr_code_scanner_rounded, label: 'Escanear'),
              RoleNavItem(icon: Icons.point_of_sale_rounded, label: 'Cobrar'),
              RoleNavItem(icon: Icons.receipt_long_rounded, label: 'Ventas'),
              RoleNavItem(icon: Icons.more_horiz_rounded, label: 'Más'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int tab, GymState state, RolePalette palette, {Key? key}) {
    switch (tab) {
      case 0:
        return _CashierHomePage(
          key: key,
          palette: palette,
          state: state,
        );
      case 1:
        return _CashierScanPage(
          key: key,
          palette: palette,
          state: state,
          scanInput: _scanDniInput,
          onScanChanged: (val) => setState(() => _scanDniInput = val),
          onTriggerVerdict: (result, member, dni) {
            _go('verdict', {'result': result, 'member': member, 'dni': dni});
          },
        );
      case 2:
        return _CashierPOSPage(
          key: key,
          palette: palette,
          state: state,
          selectedMemberDni: _selectedMemberDni,
          cartItems: _cartItems,
          cashPaid: _cashPaid,
          paymentMethod: _paymentMethod,
          onMemberChanged: (dni) => setState(() {
            _selectedMemberDni = dni;
          }),
          onCartChanged: () => setState(() {}),
          onCashPaidChanged: (val) => setState(() => _cashPaid = val),
          onPaymentMethodChanged: (val) => setState(() => _paymentMethod = val),
          onClearCart: () {
            setState(() {
              _cartItems.clear();
              _selectedMemberDni = null;
            });
          },
        );
      case 3:
        return _CashierSalesPage(
          key: key,
          palette: palette,
          state: state,
        );
      default:
        return _CashierMorePage(
          key: key,
          palette: palette,
          state: state,
        );
    }
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE6E2D8)),
  );
}

// ==========================================
// TABS IMPLEMENTATION
// ==========================================

class _CashierHomePage extends StatelessWidget {
  const _CashierHomePage({
    super.key,
    required this.palette,
    required this.state,
  });

  final RolePalette palette;
  final GymState state;

  @override
  Widget build(BuildContext context) {
    final myLogs = state.auditLogs.where((log) => log.actor.contains('Caja')).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        RoleHeroHeader(
          palette: palette,
          title: 'Caja y Accesos',
          subtitle: 'Valida ingresos, cobra operaciones y deja trazabilidad inmediata.',
          trailing: StatusPill(label: 'TURNO', color: palette.accent, solid: true),
        ),
        const SizedBox(height: 16),
        _TurnSummary(palette: palette, logs: myLogs),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Asistencias Hoy',
                value: '${state.members.where((m) => m.todayCheckIn).length}',
                note: 'Accesos en este turno',
                accent: palette.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                icon: Icons.inventory_2_outlined,
                label: 'Stock Crítico',
                value: '${state.products.where((p) => p.stock < 20).length}',
                note: 'Menos de 20 unidades',
                accent: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Operación Auditada'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Operas bajo perfil de Cajero Autorizado.',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
              ),
              const SizedBox(height: 8),
              Text(
                'Todas las transacciones de ventas y aprobaciones de asistencia son registradas con tu firma digital en la bitácora global del administrador.',
                style: TextStyle(fontSize: 12.5, color: Colors.black.withValues(alpha: 0.6), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(title: 'Mis logs de auditoría', action: '${myLogs.length} hoy'),
        if (myLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: const Center(
              child: Text(
                'No has registrado movimientos en este turno.',
                style: TextStyle(color: Color(0xFF6E6E6E), fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          Column(
            children: myLogs.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LogTile(
                  icon: entry.action.contains('Cobró') || entry.action.contains('Venta')
                      ? Icons.point_of_sale_rounded
                      : Icons.qr_code_scanner_rounded,
                  title: entry.action,
                  detail: entry.detail,
                  time: entry.time,
                  color: entry.color,
                  locked: true,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ------------------------------------------
// SCANNER SIMULATOR TAB
// ------------------------------------------
class _CashierScanPage extends StatelessWidget {
  const _CashierScanPage({
    super.key,
    required this.palette,
    required this.state,
    required this.scanInput,
    required this.onScanChanged,
    required this.onTriggerVerdict,
  });

  final RolePalette palette;
  final GymState state;
  final String scanInput;
  final Function(String) onScanChanged;
  final Function(String, MemberRecord?, String) onTriggerVerdict;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        RoleHeroHeader(
          palette: palette,
          title: 'Escáner de Sala',
          subtitle: 'Simula accesos y valida reglas de entrada al instante.',
        ),
        const SizedBox(height: 16),

        // Scanner Graphic with Overlay Grid
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2C2C2C), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Animated red laser sweep line
                const _LaserSweepLine(),
                // Corner grid markers
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: palette.accent, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.videocam_rounded, color: Colors.red, size: 14),
                          SizedBox(width: 6),
                          Text('CAM_SIMULATOR_ON',
                              style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Interactive Scanner Simulator Actions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulación de Escaneo QR',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona un socio preconfigurado o digita un DNI para probar las reglas de acceso reactivas.',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              // Preset scan test buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _scanSimButton('Mateo Salas (Activo)', '12345678'),
                  _scanSimButton('Ana Torres (En Gracia)', '55667788'),
                  _scanSimButton('Diego Castro (Vencido)', '11223344'),
                  _scanSimButton('Juan Perez (Vencido)', '00000000'),
                  _scanSimButton('DNI Inválido', '99999999'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE8E4D9)),
              const SizedBox(height: 16),
              // Custom DNI field
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2DDD5)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: onScanChanged,
                        decoration: const InputDecoration(
                          hintText: 'Digitar DNI del socio...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: roleFilledPillButtonStyle(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.accentInk,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    onPressed: () {
                      if (scanInput.isNotEmpty) {
                        _triggerScan(scanInput);
                      }
                    },
                    child: const Text('Escanear DNI', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scanSimButton(String label, String dni) {
    return ElevatedButton(
      style: roleOutlinedPillButtonStyle(
        foregroundColor: palette.accent,
        backgroundColor: palette.accent.withValues(alpha: 0.08),
        side: BorderSide(color: palette.accent.withValues(alpha: 0.18)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: () => _triggerScan(dni),
      child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
    );
  }

  void _triggerScan(String input) async {
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

    if (state.isBackendMode) {
      // Show loading or directly trigger the async verdict
      final res = await state.verifyAttendanceBackend(dni: dni, otpToken: otpToken);
      final verdict = res['verdict'];
      final member = res['member'] as MemberRecord?;

      String resultStr = 'denied';
      if (verdict == 'GREEN') resultStr = 'granted';
      if (verdict == 'AMBER') resultStr = 'grace';

      onTriggerVerdict(resultStr, member, dni);
    } else {
      // Offline/Demo Mode fallback
      final result = state.recordAttendance(dni);
      final memberIndex = state.allMembersIncludingSoftDeleted.indexWhere((m) => m.dni == dni);
      final MemberRecord? member = memberIndex != -1 ? state.allMembersIncludingSoftDeleted[memberIndex] : null;
      onTriggerVerdict(result, member, dni);
    }
  }
}

class _LaserSweepLine extends StatefulWidget {
  const _LaserSweepLine();

  @override
  State<_LaserSweepLine> createState() => _LaserSweepLineState();
}

class _LaserSweepLineState extends State<_LaserSweepLine> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Positioned(
          top: _animController.value * 230 + 5,
          left: 10,
          right: 10,
          child: Container(
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.8),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------
// VERDICT SCREEN SUB-VIEW (HIDES NAV)
// ------------------------------------------
class _ScannerVerdictView extends StatelessWidget {
  const _ScannerVerdictView({
    required this.palette,
    required this.result,
    required this.member,
    required this.dni,
    required this.onBack,
    required this.onChargeDirect,
  });

  final RolePalette palette;
  final String result;
  final MemberRecord? member;
  final String dni;
  final VoidCallback onBack;
  final Function(String) onChargeDirect;

  @override
  Widget build(BuildContext context) {
    Color bg;
    IconData icon;
    String statusTitle;
    String statusSubtitle;
    bool showPOSButton = false;

    if (result == 'granted') {
      bg = const Color(0xFF00B85C); // Green
      icon = Icons.check_circle_outline_rounded;
      statusTitle = 'ACCESO CONCEDIDO';
      statusSubtitle = 'Miembro activo y habilitado para entrenar hoy.';
    } else if (result == 'grace') {
      bg = const Color(0xFFFFB300); // Yellow
      icon = Icons.warning_amber_rounded;
      statusTitle = 'INGRESO EN GRACIA';
      statusSubtitle = 'Miembro habilitado por hoy. Su plan requiere renovación inmediata.';
      showPOSButton = true;
    } else if (result == 'denied') {
      bg = const Color(0xFFFF3B30); // Red
      icon = Icons.cancel_outlined;
      statusTitle = 'ACCESO DENEGADO';
      statusSubtitle = member != null
          ? 'Membresía vencida. El socio debe regularizar su estado de pago.'
          : 'Usuario inactivo o suspendido.';
      showPOSButton = member != null;
    } else {
      // not_found
      bg = const Color(0xFF5C5C5C); // Grey
      icon = Icons.search_off_rounded;
      statusTitle = 'DNI NO REGISTRADO';
      statusSubtitle = 'El DNI $dni no figura en el padrón de socios.';
    }

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Big Icon
              Icon(icon, size: 96, color: Colors.white),
              const SizedBox(height: 24),
              // Status Title
              Text(
                statusTitle,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Status Subtitle
              Text(
                statusSubtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14.5, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Student Data Sheet Card if member exists
              if (member != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2DDD5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: palette.accent.withValues(alpha: 0.15),
                        foregroundColor: Colors.black,
                        child: Text(member!.name.substring(0, 2).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member!.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black)),
                            const SizedBox(height: 2),
                            Text('DNI: ${member!.dni} · Plan actual: ${member!.goal}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 36),

              // Action buttons
              if (showPOSButton) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: roleFilledPillButtonStyle(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.point_of_sale_rounded, color: Colors.orange),
                    label: const Text('Cobrar Renovación en POS', style: TextStyle(fontWeight: FontWeight.w900)),
                    onPressed: () {
                      onChargeDirect(member!.dni);
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: roleTextPillButtonStyle(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onBack,
                  child: const Text('Cerrar y Reintentar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------
// POS CHECKOUT TAB
// ------------------------------------------
class _CashierPOSPage extends StatefulWidget {
  const _CashierPOSPage({
    super.key,
    required this.palette,
    required this.state,
    required this.selectedMemberDni,
    required this.cartItems,
    required this.cashPaid,
    required this.paymentMethod,
    required this.onMemberChanged,
    required this.onCartChanged,
    required this.onCashPaidChanged,
    required this.onPaymentMethodChanged,
    required this.onClearCart,
  });

  final RolePalette palette;
  final GymState state;
  final String? selectedMemberDni;
  final List<Map<String, dynamic>> cartItems;
  final double cashPaid;
  final String paymentMethod;
  final Function(String?) onMemberChanged;
  final VoidCallback onCartChanged;
  final Function(double) onCashPaidChanged;
  final Function(String) onPaymentMethodChanged;
  final VoidCallback onClearCart;

  @override
  State<_CashierPOSPage> createState() => _CashierPOSPageState();
}

class _CashierPOSPageState extends State<_CashierPOSPage> {
  // Available POS inventory (plans + physical goods)
  final List<Map<String, dynamic>> _posItems = [
    {'name': 'Plan Mensual Oro', 'price': 150.0, 'icon': '🏋️', 'category': 'Planes'},
    {'name': 'Plan Mensual Plata', 'price': 120.0, 'icon': '🥈', 'category': 'Planes'},
    {'name': 'Plan Trimestral', 'price': 400.0, 'icon': '💎', 'category': 'Planes'},
    {'name': 'Botella de agua 600ml', 'price': 3.0, 'icon': '💧', 'category': 'Bebidas'},
    {'name': 'Proteína whey porción', 'price': 12.0, 'icon': '💪', 'category': 'Suplementos'},
    {'name': 'Pre-entreno scoop', 'price': 8.0, 'icon': '⚡', 'category': 'Suplementos'},
    {'name': 'Barra energética', 'price': 5.0, 'icon': '🍫', 'category': 'Snacks'},
  ];

  @override
  Widget build(BuildContext context) {
    final double subtotal = widget.cartItems.fold(0, (sum, item) => sum + (item['price'] * item['qty']));
    final double discount = subtotal > 300.0 ? subtotal * 0.05 : 0.0; // 5% discount for bulk
    final double total = subtotal - discount;
    final double change = (widget.cashPaid - total).clamp(0.0, 99999.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        const SectionHeader(title: 'Punto de Venta (POS)', action: 'Carrito de compras'),
        const SizedBox(height: 8),

        // Member selection dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: _cardDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: widget.selectedMemberDni,
              hint: const Text('Seleccionar Socio destinatario...', style: TextStyle(fontWeight: FontWeight.w600)),
              items: widget.state.members.map((m) {
                return DropdownMenuItem(
                  value: m.dni,
                  child: Text('${m.name} (DNI ${m.dni}) · Plan: ${m.state}'),
                );
              }).toList(),
              onChanged: widget.onMemberChanged,
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Cart items display
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Items en Carrito', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                  const Spacer(),
                  if (widget.cartItems.isNotEmpty)
                    TextButton(
                      onPressed: widget.onClearCart,
                      child: const Text('Vaciar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.cartItems.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('El carrito está vacío. Agrega items del catálogo inferior.',
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                )
              else
                Column(
                  children: [
                    ...widget.cartItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(item['icon'], style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                  Text('S/ ${item['price']} x ${item['qty']}', style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                                ],
                              ),
                            ),
                            // Qty controls
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () {
                                setState(() {
                                  if (item['qty'] > 1) {
                                    item['qty']--;
                                  } else {
                                    widget.cartItems.remove(item);
                                  }
                                });
                                widget.onCartChanged();
                              },
                            ),
                            Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: () {
                                setState(() {
                                  item['qty']++;
                                });
                                widget.onCartChanged();
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20, color: Color(0xFFE8E4D9)),
                    _priceSummaryRow('Subtotal', 'S/ ${subtotal.toStringAsFixed(2)}'),
                    _priceSummaryRow('Descuento', '- S/ ${discount.toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL COBRO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        Text('S/ ${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Colors.orange)),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Checkout & Payment Methods Drawer
        if (widget.cartItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Método de Pago', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: ['Efectivo', 'Yape', 'Plin', 'Tarjeta'].map((m) {
                    final selected = widget.paymentMethod == m;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(m, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: selected ? Colors.white : Colors.black)),
                          selected: selected,
                          selectedColor: widget.palette.accent,
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(color: Color(0xFFE8E4D9)),
                          shape: const StadiumBorder(),
                          onSelected: (val) {
                            if (val) widget.onPaymentMethodChanged(m);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Cash Change Calculator
                if (widget.paymentMethod == 'Efectivo') ...[
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Efectivo Recibido (S/)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2DDD5)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            widget.onCashPaidChanged(double.tryParse(val) ?? 0.0);
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cambio / Vuelto a Entregar:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('S/ ${change.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Confirm Checkout
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: roleFilledPillButtonStyle(
                      backgroundColor: widget.palette.accent,
                      foregroundColor: widget.palette.accentInk,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (widget.selectedMemberDni == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor, selecciona un Socio destinatario primero')),
                        );
                        return;
                      }

                      if (widget.state.isBackendMode) {
                        try {
                          final ok = await widget.state.chargePOSBackend(
                            memberDni: widget.selectedMemberDni!,
                            cartItems: widget.cartItems,
                            total: total,
                            paymentMethod: widget.paymentMethod,
                          );
                          if (ok) {
                            if (context.mounted) {
                              _showPOSReceiptSuccess(context, total, widget.paymentMethod);
                            }
                            widget.onClearCart();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            String errorMsg = 'Error al procesar la venta en el servidor.';
                            if (e is DioException && e.response != null && e.response!.data != null) {
                              final data = e.response!.data;
                              if (data is Map && data.containsKey('message')) {
                                errorMsg = data['message'].toString();
                              }
                            }
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('Operación Denegada', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                content: Text(errorMsg),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      } else {
                        // Demo mode fallback
                        widget.state.chargePOS(
                          memberDni: widget.selectedMemberDni!,
                          cartItems: widget.cartItems,
                          total: total,
                          paymentMethod: widget.paymentMethod,
                        );
                        _showPOSReceiptSuccess(context, total, widget.paymentMethod);
                        widget.onClearCart();
                      }
                    },
                    child: const Text('PROCESAR Y EMITIR RECIBO', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 22),

        // Catalog header
        const SectionHeader(title: 'Catálogo POS de Venta'),
        Column(
          children: _posItems.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2DDD5)),
              ),
              child: ListTile(
                leading: Text(item['icon'] as String, style: const TextStyle(fontSize: 22)),
                title: Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(item['category'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('S/ ${item['price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.orange),
                      onPressed: () {
                        setState(() {
                          final idx = widget.cartItems.indexWhere((c) => c['name'] == item['name']);
                          if (idx != -1) {
                            widget.cartItems[idx]['qty']++;
                          } else {
                            widget.cartItems.add({
                              'name': item['name'],
                              'price': item['price'],
                              'qty': 1,
                              'icon': item['icon'],
                            });
                          }
                        });
                        widget.onCartChanged();
                      },
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

  Widget _priceSummaryRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _showPOSReceiptSuccess(BuildContext context, double total, String method) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2DDD5)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00B85C), size: 64),
              const SizedBox(height: 18),
              const Text('Venta Completada', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 8),
              Text('Se registró el cobro de S/ $total via $method correctamente.',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: roleFilledPillButtonStyle(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  minimumHeight: 44,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------
// SALES REPORT TAB
// ------------------------------------------
class _CashierSalesPage extends StatelessWidget {
  const _CashierSalesPage({
    super.key,
    required this.palette,
    required this.state,
  });

  final RolePalette palette;
  final GymState state;

  @override
  Widget build(BuildContext context) {
    final cashierSalesLogs = state.auditLogs
        .where((log) => log.actor.contains('Caja') && (log.action.contains('Venta') || log.action.contains('Cobró')))
        .toList();

    double totalTurnRevenue = cashierSalesLogs.fold(0, (sum, log) {
      // Simple mock parser: extract digits from details like "Rosa Mendieta · S/ 120"
      final reg = RegExp(r'S/\s*([0-9.]+)');
      final match = reg.firstMatch(log.detail);
      if (match != null) {
        return sum + (double.tryParse(match.group(1)!) ?? 0.0);
      }
      return sum;
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        const SectionHeader(title: 'Reportes de Ventas', action: 'Turno en curso'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Expanded(child: _posStatBox('Ventas Totales', '${cashierSalesLogs.length}', 'registradas')),
              const SizedBox(width: 10),
              Expanded(child: _posStatBox('Recaudación', 'S/ ${totalTurnRevenue.toStringAsFixed(2)}', 'en caja')),
            ],
          ),
        ),
        const SizedBox(height: 22),

        SectionHeader(
          title: 'Historial del Turno',
          action: 'Solicitar anulación',
        ),
        if (cashierSalesLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: const Center(
              child: Text(
                'No has realizado ventas en este turno.',
                style: TextStyle(color: Color(0xFF6E6E6E), fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          Column(
            children: cashierSalesLogs.map((log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.action, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                          const SizedBox(height: 2),
                          Text(log.detail, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(log.time, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Solicitud de anulación enviada al Administrador para: ${log.action}'),
                                backgroundColor: palette.accent,
                              ),
                            );
                          },
                          child: const Text(
                            'Anular',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _posStatBox(String title, String val, String note) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E4D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF707070), fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(note, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ------------------------------------------
// MORE OPTIONS / PRODUCT & MEMBER CRUD
// ------------------------------------------
class _CashierMorePage extends StatefulWidget {
  const _CashierMorePage({
    super.key,
    required this.palette,
    required this.state,
  });

  final RolePalette palette;
  final GymState state;

  @override
  State<_CashierMorePage> createState() => _CashierMorePageState();
}

class _CashierMorePageState extends State<_CashierMorePage> {
  String _productSearch = '';
  String _memberSearch = '';

  @override
  Widget build(BuildContext context) {
    final filteredProds = widget.state.products
        .where((p) => p.name.toLowerCase().contains(_productSearch.toLowerCase()))
        .toList();

    final filteredMembers = widget.state.members
        .where((m) => m.name.toLowerCase().contains(_memberSearch.toLowerCase()) || m.dni.contains(_memberSearch))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          tabs: [
            Tab(text: 'Productos'),
            Tab(text: 'Socios (Baja Lógica)'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        body: TabBarView(
          children: [
            // Products List (Cashier can add and edit prices, but not physical delete)
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton.icon(
                  style: roleOutlinedPillButtonStyle(
                    foregroundColor: widget.palette.accent,
                    backgroundColor: widget.palette.accent.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Agregar Nuevo Producto', style: TextStyle(fontWeight: FontWeight.w900)),
                  onPressed: () => _showAddProductDialog(context),
                ),
                const SizedBox(height: 14),
                // Search
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2DDD5)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    onChanged: (val) => setState(() => _productSearch = val),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      hintText: 'Buscar producto...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Column(
                  children: filteredProds.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: _cardDecoration(),
                      child: Row(
                        children: [
                          Text(p.icon, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text('${p.category} · Stock: ${p.stock}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('S/ ${p.price}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Edit price
                                  GestureDetector(
                                    onTap: () => _showEditPriceDialog(context, p),
                                    child: const Text('Editar',
                                        style: TextStyle(
                                            color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11.5)),
                                  ),
                                  const SizedBox(width: 12),
                                  // Physical delete (disabled for cashier)
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Error: La eliminación física requiere rol de Administrador'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Borrar',
                                      style: TextStyle(
                                        color: Colors.red.withValues(alpha: 0.4),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Members list with Soft Delete (Baja Lógica)
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2DDD5)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    onChanged: (val) => setState(() => _memberSearch = val),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      hintText: 'Buscar socio por nombre o DNI...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Column(
                  children: filteredMembers.map((m) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: _cardDecoration(),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: widget.palette.accent.withValues(alpha: 0.12),
                            child: Text(m.name.substring(0, 2).toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text('DNI: ${m.dni} · ${m.goal}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                              ],
                            ),
                          ),
                          // Soft delete action
                          ElevatedButton(
                            style: roleFilledPillButtonStyle(
                              backgroundColor: const Color(0xFFFFECEB),
                              foregroundColor: const Color(0xFFFF3B30),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumHeight: 36,
                            ),
                            onPressed: () {
                              _confirmSoftDelete(context, m);
                            },
                            child: const Text('Baja Lógica',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    String name = '';
    String category = 'Suplementos';
    double price = 0.0;
    int stock = 10;
    String icon = '📦';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2DDD5)),
          ),
          title: const Text('Registrar Producto', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                onChanged: (val) => name = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Categoría'),
                onChanged: (val) => category = val,
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio (S/)'),
                onChanged: (val) => price = double.tryParse(val) ?? 0.0,
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock Inicial'),
                onChanged: (val) => stock = int.tryParse(val) ?? 10,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: widget.palette.accent),
              onPressed: () {
                if (name.isNotEmpty) {
                  widget.state.addProduct(ProductItem(
                    name: name,
                    category: category,
                    price: price,
                    stock: stock,
                    icon: icon,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: Text('Registrar', style: TextStyle(color: widget.palette.accentInk)),
            ),
          ],
        );
      },
    );
  }

  void _showEditPriceDialog(BuildContext context, ProductItem item) {
    double price = item.price;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2DDD5)),
          ),
          title: Text('Modificar Precio', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Producto: ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Nuevo Precio (S/)', hintText: '${item.price}'),
                onChanged: (val) => price = double.tryParse(val) ?? item.price,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: widget.palette.accent),
              onPressed: () {
                widget.state.updateProduct(item.name, item.copyWith(price: price));
                Navigator.pop(ctx);
              },
              child: Text('Guardar', style: TextStyle(color: widget.palette.accentInk)),
            ),
          ],
        );
      },
    );
  }

  void _confirmSoftDelete(BuildContext context, MemberRecord member) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2C2C2C)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_sweep_rounded, color: Colors.orange, size: 54),
              const SizedBox(height: 16),
              const Text('¿Desactivar Socio?',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
              const SizedBox(height: 10),
              Text(
                'Se realizará la Baja Lógica de ${member.name}. Mantendremos su historial financiero intacto pero perderá acceso inmediato a la sala de entrenamiento.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        widget.state.toggleMemberLogicDelete(member.dni);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${member.name} desactivado (Baja Lógica)'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      child: const Text('Desactivar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// CARD DECORATION & SUMMARY HELPERS
class _TurnSummary extends StatelessWidget {
  const _TurnSummary({required this.palette, required this.logs});

  final RolePalette palette;
  final List<AuditEntry> logs;

  @override
  Widget build(BuildContext context) {
    // Calculate total receipts
    final chargeLogs = logs.where((l) => l.action.contains('Cobró') || l.action.contains('Venta'));
    double revenue = 0;
    final reg = RegExp(r'S/\s*([0-9.]+)');
    for (var l in chargeLogs) {
      final match = reg.firstMatch(l.detail);
      if (match != null) {
        revenue += double.tryParse(match.group(1)!) ?? 0.0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Saldo del turno', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w900, color: palette.accent)),
              const Spacer(),
              StatusPill(label: 'CIERRA 14:00', color: palette.accent, solid: true),
            ],
          ),
          const SizedBox(height: 10),
          Text('S/ ${revenue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.8)),
          const SizedBox(height: 4),
          Text('${chargeLogs.length} transacciones registradas en este turno.', style: const TextStyle(fontSize: 13, color: Color(0xFFB7B7B7), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
