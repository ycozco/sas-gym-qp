import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../data/gym_seed.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';
import '../widgets/workout_assistant_view.dart';
import '../widgets/pay_membership_view.dart';
import '../widgets/full_qr_view.dart';
import '../widgets/member_diet_view.dart';
import '../widgets/member_home_page.dart';
import '../widgets/member_agenda_page.dart';
import '../widgets/member_subscription_page.dart';
import '../widgets/member_profile_page.dart';
import '../widgets/class_booking_view.dart';
import '../widgets/report_observation_view.dart';
import '../widgets/notifications_view.dart';

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

  Color _getAccentColor() {
    if (!Hive.isBoxOpen('gym_cache')) {
      return rolePalettes[GymRole.member]!.accent;
    }
    final box = Hive.box('gym_cache');
    final savedColor = box.get('custom_theme_accent');
    if (savedColor != null && savedColor is int) {
      return Color(savedColor);
    }
    return rolePalettes[GymRole.member]!.accent;
  }

  @override
  Widget build(BuildContext context) {
    final defaultPalette = rolePalettes[GymRole.member]!;
    final customAccent = _getAccentColor();
    final palette = RolePalette(
      accent: customAccent,
      accentInk: customAccent.computeLuminance() > 0.45
          ? const Color(0xFF0B0B0B)
          : Colors.white,
      surfaceTint: defaultPalette.surfaceTint,
      gradient: LinearGradient(
        colors: [customAccent.withOpacity(0.15), const Color(0xFF0F0F11)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      label: defaultPalette.label,
    );

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
        activeView = ClassBookingView(palette: palette, onBack: _back);
      } else if (screen == 'observation') {
        activeView = ReportObservationView(palette: palette, onBack: _back);
      } else if (screen == 'notifications') {
        activeView = NotificationsView(palette: palette, onBack: _back);
      } else if (screen == 'diet') {
        activeView = MemberDietView(palette: palette, onBack: _back);
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
        return MemberHomePage(key: key, palette: palette, onGo: _go);
      case 1:
        return MemberAgendaPage(key: key, palette: palette, onGo: _go);
      case 2:
        return MemberSubscriptionPage(key: key, palette: palette, onGo: _go);
      default:
        return MemberProfilePage(
          key: key,
          palette: palette,
          onGo: _go,
          onThemeChanged: () => setState(() {}),
        );
    }
  }
}
