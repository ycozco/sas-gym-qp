import 'package:flutter/material.dart';

import '../../../data/gym_seed.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';
import '../widgets/admin_payment_approvals_page.dart';
import '../widgets/admin_audit_logs_page.dart';
import '../widgets/admin_dashboard_page.dart';
import '../widgets/admin_members_page.dart';
import '../widgets/admin_member_detail_page.dart';
import '../widgets/admin_member_form_page.dart';
import '../widgets/admin_scanner_page.dart';
import '../widgets/admin_cashiers_page.dart';
import '../widgets/admin_more_page.dart';
import '../widgets/admin_product_pages.dart';
import '../widgets/admin_ops_pages.dart';
import '../widgets/admin_verdict_view.dart';
import '../widgets/admin_caja_audit_page.dart';

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

        activeView = AdminVerdictView(
          palette: palette,
          result: scanResult,
          member: member,
          dni: dni,
          onBack: _back,
          membershipPlans: state.membershipPlans,
          onChargeDirect: (memberDni, {planName, price}) {
            _back();
            setState(() {
              _currentTab = 1; // Go to Users tab
              _memberSearchQuery = memberDni;
            });
            final idx = state.members.indexWhere((m) => m.dni == memberDni);
            if (idx != -1) {
              _go('member_detail', {'member': state.members[idx]});
            }
          },
          onCreateNewClient: (newDni) {
            _back();
            _go('member_form', {'prefilledDni': newDni});
          },
        );
      } else if (screen == 'member_detail') {
        final MemberRecord member = params?['member'] as MemberRecord;
        activeView = AdminMemberDetailPage(
          palette: palette,
          state: state,
          memberDni: member.dni,
          onBack: _back,
          onEdit: (m) => _go('member_form', {'member': m}),
        );
      } else if (screen == 'member_form') {
        final MemberRecord? member = params?['member'] as MemberRecord?;
        final String? prefilledDni = params?['prefilledDni'] as String?;
        activeView = AdminMemberFormPage(
          palette: palette,
          state: state,
          member: member,
          prefilledDni: prefilledDni,
          onBack: _back,
        );
      } else if (screen == 'payment_approvals') {
        activeView = AdminPaymentApprovalsPage(
          palette: palette,
          state: state,
          onBack: _back,
        );
      } else if (screen == 'product_inventory') {
        activeView = AdminProductInventoryPage(
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
        activeView = AdminProductFormPage(
          palette: palette,
          state: state,
          product: product,
          onBack: _back,
        );
      } else if (screen == 'audit_logs') {
        activeView = AdminAuditLogsPage(
          palette: palette,
          state: state,
          filterActor: _auditFilterActor,
          searchQuery: _auditSearchQuery,
          onActorChanged: (val) => setState(() => _auditFilterActor = val),
          onSearchChanged: (val) => setState(() => _auditSearchQuery = val),
          onBack: _back,
        );
      } else if (screen == 'observations') {
        activeView = AdminObservationsPage(
          palette: palette,
          state: state,
          onBack: _back,
        );
      } else if (screen == 'announcement_form') {
        activeView = AdminAnnouncementFormPage(
          palette: palette,
          state: state,
          onBack: _back,
        );
      } else if (screen == 'settings') {
        activeView = AdminSettingsPage(
          palette: palette,
          state: state,
          onBack: _back,
        );
      } else if (screen == 'caja_audit') {
        activeView = AdminCajaAuditPage(
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
        return AdminDashboardPage(
          key: key,
          palette: palette,
          state: state,
          onGoApprovals: () => _go('payment_approvals'),
          onGoCreateMember: () => _go('member_form'),
          onGoSettings: () => _go('settings'),
          onGoAuditLogs: () => _go('audit_logs'),
          onGoCajaAudit: () => _go('caja_audit'),
        );
      case 1:
        return AdminMembersPage(
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
        return AdminScannerPage(
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
        return AdminCashiersPage(
          key: key,
          palette: palette,
          state: state,
        );
      default:
        return AdminMorePage(
          key: key,
          palette: palette,
          state: state,
          onNavigate: (route) => _go(route),
        );
    }
  }
}
