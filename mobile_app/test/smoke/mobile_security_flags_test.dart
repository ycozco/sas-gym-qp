import 'package:flutter/material.dart';
import 'package:flutter_app/data/gym_seed.dart';
import 'package:flutter_app/data/gym_state.dart';
import 'package:flutter_app/features/auth/screens/login_screen.dart';
import 'package:flutter_app/features/member/widgets/full_qr_view.dart';
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
    memberProfile: {
      'objetivo': 'QA',
      'qr_secret': 'backend-issued-secret',
    },
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
    memberProfile: {
      'objetivo': 'QA',
    },
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

  testWidgets('member QR renders when backend qr_secret exists', (tester) async {
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

  testWidgets('member QR without backend secret shows unavailable state', (tester) async {
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
