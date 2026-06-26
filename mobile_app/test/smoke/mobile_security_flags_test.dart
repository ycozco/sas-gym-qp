import 'package:flutter/material.dart';
import 'package:flutter_app/data/gym_seed.dart';
import 'package:flutter_app/data/gym_state.dart';
import 'package:flutter_app/core/config/app_config.dart';
import 'package:flutter_app/features/auth/screens/login_screen.dart';
import 'package:flutter_app/features/member/widgets/class_booking_view.dart';
import 'package:flutter_app/features/member/widgets/full_qr_view.dart';
import 'package:flutter_app/features/member/widgets/notifications_view.dart';
import 'package:flutter_app/models/gym_models.dart';
import 'package:flutter_test/flutter_test.dart';

LoggedInUser _memberWithQrSecret() {
  return LoggedInUser(
    id: 'member-id',
    email: 'member@example.com',
    rol: GymRole.member,
    nombreCompleto: 'Member Test',
    dni: '11111111',
    estado: 'ACTIVE',
    memberProfile: {'objetivo': 'QA', 'qr_secret': 'backend-issued-secret'},
  );
}

LoggedInUser _memberWithoutQrSecret() {
  return LoggedInUser(
    id: 'member-id',
    email: 'member@example.com',
    rol: GymRole.member,
    nombreCompleto: 'Member Test',
    dni: '11111111',
    estado: 'ACTIVE',
    memberProfile: {'objetivo': 'QA'},
  );
}

void main() {
  testWidgets('demo login panel is hidden by default', (tester) async {
    final state = GymState(startBackground: false);
    addTearDown(state.dispose);

    await tester.pumpWidget(
      GymStateProvider(
        notifier: state,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Modo Demo / Cuentas Semilla'), findsNothing);
  });

  test('backend mode does not preload demo seed data', () {
    final state = GymState(startBackground: false);
    addTearDown(state.dispose);

    expect(state.allMembersIncludingSoftDeleted, isEmpty);
    expect(state.products, isEmpty);
    expect(state.auditLogs, isEmpty);
  });

  test('demo mode requires explicit build authorization', () {
    expect(
      () => AppConfig.resolveMode('demo', allowDemoMode: false),
      throwsA(isA<StateError>()),
    );
    expect(AppConfig.resolveMode('demo', allowDemoMode: true), AppMode.demo);
    expect(
      AppConfig.resolveMode('backend', allowDemoMode: false),
      AppMode.backend,
    );
  });

  test('mobile backend mode requires explicit API_BASE_URL', () {
    expect(AppConfig.resolveApiBaseUrl, throwsA(isA<StateError>()));
  });

  testWidgets('class booking does not render embedded demo schedules', (
    tester,
  ) async {
    final state = GymState(startBackground: false);
    addTearDown(state.dispose);

    await tester.pumpWidget(
      GymStateProvider(
        notifier: state,
        child: MaterialApp(
          home: ClassBookingView(
            palette: rolePalettes[GymRole.member]!,
            onBack: () {},
          ),
        ),
      ),
    );

    expect(find.text('Crossfit WOD'), findsNothing);
    expect(find.text('No hay clases disponibles'), findsOneWidget);
  });

  testWidgets(
    'notifications view does not render embedded demo notifications',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsView(
            palette: rolePalettes[GymRole.member]!,
            onBack: () {},
          ),
        ),
      );

      expect(find.text('Membresía activa'), findsNothing);
      expect(find.text('Nueva Rutina Asignada'), findsNothing);
      expect(find.text('No hay notificaciones'), findsOneWidget);
    },
  );

  testWidgets('member QR renders when backend qr_secret exists', (
    tester,
  ) async {
    final state = GymState(startBackground: false);
    addTearDown(state.dispose);
    state.setCurrentGymActiveForTest(active: true);
    state.setCurrentUserForTest(_memberWithQrSecret());

    await tester.pumpWidget(
      GymStateProvider(
        notifier: state,
        child: MaterialApp(
          home: FullQRView(
            palette: rolePalettes[GymRole.member]!,
            onBack: () {},
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Token:'), findsOneWidget);
    expect(find.textContaining('QR no disponible'), findsNothing);
  });

  testWidgets('member QR without backend secret shows unavailable state', (
    tester,
  ) async {
    final state = GymState(startBackground: false);
    addTearDown(state.dispose);
    state.setCurrentGymActiveForTest(active: true);
    state.setCurrentUserForTest(_memberWithoutQrSecret());

    await tester.pumpWidget(
      GymStateProvider(
        notifier: state,
        child: MaterialApp(
          home: FullQRView(
            palette: rolePalettes[GymRole.member]!,
            onBack: () {},
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('QR no disponible'), findsOneWidget);
    expect(find.textContaining('Token:'), findsNothing);
  });
}
