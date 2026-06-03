import 'package:flutter/material.dart';
import 'package:flutter_app/data/gym_seed.dart';
import 'package:flutter_app/data/gym_state.dart';
import 'package:flutter_app/features/cashier/widgets/cashier_scan_page.dart';
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

LoggedInUser _cashierUser() {
  return LoggedInUser(
    id: 'cashier-id',
    email: 'cashier@example.com',
    rol: GymRole.cashier,
    nombreCompleto: 'Cashier Test',
    dni: '87654321',
    estado: 'ACTIVE',
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

  testWidgets('cashier backend scan with DNI only is denied locally', (tester) async {
    final state = GymState(startBackground: false);
    addTearDown(state.dispose);
    state.setCurrentGymActiveForTest(active: true);
    state.setCurrentUserForTest(_cashierUser());

    String? result;
    String? scannedDni;

    await tester.pumpWidget(
      MaterialApp(
        home: GymStateProvider(
          notifier: state,
          child: Scaffold(
            body: CashierScanPage(
              palette: rolePalettes[GymRole.cashier]!,
              state: state,
              scanInput: '11111111',
              onScanChanged: (_) {},
              onTriggerVerdict: (nextResult, _, dni) {
                result = nextResult;
                scannedDni = dni;
              },
              onDayPass: (_, {planName, price}) {},
            ),
          ),
        ),
      ),
    );

    final scanButton = find.text('Escanear DNI');
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(scanButton);
    await tester.pump();

    expect(result, 'denied');
    expect(scannedDni, '11111111');
  });
}
