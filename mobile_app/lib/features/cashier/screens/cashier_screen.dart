import 'package:flutter/material.dart';
import '../../../data/gym_seed.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';
import '../widgets/scanner_verdict_view.dart';
import '../widgets/cashier_pos_page.dart';
import '../widgets/cashier_home_page.dart';
import '../widgets/cashier_scan_page.dart';
import '../widgets/cashier_sales_page.dart';
import '../widgets/cashier_memberships_page.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  int _currentTab = 0;
  int _scanSession = 0;
  final List<Map<String, dynamic>> _historyStack = [];

  // POS State
  String? _selectedMemberDni;
  final List<Map<String, dynamic>> _cartItems = [];
  double _cashPaid = 0;
  String _paymentMethod = 'Efectivo'; // Efectivo, Yape, Plin, Tarjeta

  // Scanner state
  String _scanDniInput = '';
  String? _prefilledMemberDni;
  String? _prefilledPlanName;
  double? _prefilledPlanPrice;

  void _go(String screen, [Map<String, dynamic>? params]) {
    setState(() {
      _historyStack.add({'screen': screen, 'params': params});
    });
  }

  void _back() {
    if (_historyStack.isNotEmpty) {
      setState(() {
        final screen = _historyStack.last['screen'];
        _historyStack.removeLast();
        if (screen == 'verdict') {
          _scanSession++;
          _currentTab = 1;
        }
      });
    }
  }

  // Helper to switch tab and auto-populate POS for scanner denied redirection
  void _redirectScannerToPOS(
    String memberDni, {
    String? planName,
    double? price,
  }) {
    setState(() {
      _historyStack.clear();
      _currentTab = 2; // POS tab
      _selectedMemberDni = memberDni;
      _cartItems.clear();
      // Auto-add selected or default membership plan
      _cartItems.add({
        'name': planName ?? 'Plan Mensual Oro',
        'price': price ?? 150.0,
        'qty': 1,
        'icon': '🏋️‍♂️',
      });
      _cashPaid = price ?? 150.0;
    });
  }

  // Redirect from scanner verdict to Memberships tab with pre-selected member & plan
  void _redirectScannerToMembership(
    String memberDni, {
    String? planName,
    double? price,
  }) {
    setState(() {
      _historyStack.clear();
      _currentTab = 4; // Memberships tab
      _prefilledMemberDni = memberDni;
      _prefilledPlanName = planName;
      _prefilledPlanPrice = price;
    });
  }

  void _returnToHome() {
    setState(() {
      _historyStack.clear();
      _currentTab = 0;
      _scanDniInput = '';
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

        activeView = ScannerVerdictView(
          palette: palette,
          result: scanResult,
          member: member,
          dni: dni,
          onBack: scanResult == 'granted' ? _returnToHome : _back,
          membershipPlans: state.membershipPlans,
          onChargeDirect: (memberDni, {planName, price}) {
            _redirectScannerToMembership(
              memberDni,
              planName: planName,
              price: price,
            );
          },
          onCreateNewClient: (newDni) {
            _back();
            setState(() {
              _prefilledMemberDni = newDni;
              _currentTab = 4; // Go to Memberships tab
            });
          },
        );
      }
    }

    if (activeView != null) {
      if (hideNav) {
        return activeView;
      }
      return Column(children: [Expanded(child: activeView)]);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildTab(
                _currentTab,
                state,
                palette,
                key: ValueKey<int>(_currentTab),
              ),
            ),
          ),
          RoleNavBar(
            currentIndex: _currentTab,
            accent: palette.accent,
            accentInk: palette.accentInk,
            onChanged: (index) {
              setState(() => _currentTab = index);
              if (index == 3) {
                state.loadCajaSalesBackend();
              }
            },
            items: const [
              RoleNavItem(icon: Icons.home_rounded, label: 'Inicio'),
              RoleNavItem(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Escanear',
              ),
              RoleNavItem(icon: Icons.point_of_sale_rounded, label: 'POS'),
              RoleNavItem(icon: Icons.receipt_long_rounded, label: 'Ventas'),
              RoleNavItem(
                icon: Icons.card_membership_rounded,
                label: 'Membresías',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int tab, GymState state, RolePalette palette, {Key? key}) {
    switch (tab) {
      case 0:
        return CashierHomePage(key: key, palette: palette, state: state);
      case 1:
        return CashierScanPage(
          key: ValueKey<String>('cashier-scan-$_scanSession'),
          palette: palette,
          state: state,
          scanInput: _scanDniInput,
          onScanChanged: (val) => setState(() => _scanDniInput = val),
          onTriggerVerdict: (result, member, dni) {
            _go('verdict', {'result': result, 'member': member, 'dni': dni});
          },
          onDayPass: (memberDni, {planName, price}) {
            _redirectScannerToPOS(memberDni, planName: planName, price: price);
          },
        );
      case 2:
        return CashierPOSPage(
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
        return CashierSalesPage(key: key, palette: palette, state: state);
      default:
        return CashierMembershipsPage(
          key: key,
          palette: palette,
          state: state,
          prefilledDni: _prefilledMemberDni,
          prefilledPlanName: _prefilledPlanName,
          prefilledPlanPrice: _prefilledPlanPrice,
          onClearPrefilledDni: () {
            setState(() {
              _prefilledMemberDni = null;
              _prefilledPlanName = null;
              _prefilledPlanPrice = null;
            });
          },
          onSellPlan: (memberDni, {planName, price}) {
            _redirectScannerToPOS(memberDni, planName: planName, price: price);
          },
        );
    }
  }
}
