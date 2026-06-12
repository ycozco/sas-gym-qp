import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/data/gym_seed.dart';
import 'package:flutter_app/data/gym_state.dart';
import 'package:flutter_app/features/admin/widgets/admin_scanner_page.dart';
import 'package:flutter_app/models/gym_models.dart';
import 'package:flutter_app/theme/app_theme.dart';
import 'package:flutter_app/theme/app_theme_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

LoggedInUser _userForRole(GymRole role, {String themePreference = 'dark'}) {
  return LoggedInUser(
    id: '${role.name}-id',
    email: '${role.name}@example.com',
    rol: role,
    nombreCompleto: 'Usuario ${role.name}',
    dni: '11111111',
    estado: 'ACTIVE',
    themePreference: themePreference,
  );
}

MemberRecord _memberForState(String dni, String name, String state) {
  return MemberRecord(
    dni: dni,
    name: name,
    phone: '999999999',
    email: '$dni@example.com',
    startDate: '2026-06-01',
    goal: 'QA',
    sessions: 0,
    lastSeen: 'Hoy',
    state: state,
    assignedTrainer: '',
    paymentHistory: const [],
    physicalMeasurements: const {},
    progressImages: const [],
  );
}

Future<void> _pumpDark(
  WidgetTester tester,
  Widget child, {
  GymState? state,
}) async {
  final app = MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.dark,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(1440, 3000)),
      child: Scaffold(
        body: state == null
            ? child
            : GymStateProvider(
                notifier: state,
                child: child,
              ),
      ),
    ),
  );
  await tester.pumpWidget(app);
  await tester.pump();
}

void main() {
  test('scanner presets group members by state and append invalid DNI', () {
    final state = GymState(startBackground: false);
    addTearDown(state.dispose);

    state.addMember(_memberForState('20000000', 'Alicia Activa', 'active'));
    state.addMember(_memberForState('20000003', 'Brisa En Gracia', 'grace'));
    state.addMember(_memberForState('20000004', 'Diego Vencido', 'expired'));
    state.addMember(_memberForState('20000001', 'Bruno Inactivo', 'inactive'));
    state.addMember(_memberForState('20000002', 'Carla Suspendida', 'suspended'));

    final labels = state.scannerPresets.map((preset) => preset.label).toList();

    expect(labels.any((label) => label.endsWith('(Activo)')), isTrue);
    expect(labels.any((label) => label.endsWith('(En gracia)')), isTrue);
    expect(labels.any((label) => label.endsWith('(Vencido)')), isTrue);
    expect(labels.any((label) => label.endsWith('(Inactivo)')), isTrue);
    expect(labels.any((label) => label.endsWith('(Suspendido)')), isTrue);
    expect(labels.last, 'DNI inválido');
  });

  testWidgets('admin scanner renders dynamic presets with proper accents', (
    tester,
  ) async {
    final state = GymState(startBackground: false);
    addTearDown(state.dispose);

    state.addMember(_memberForState('20000001', 'Bruno Inactivo', 'inactive'));
    state.addMember(_memberForState('20000002', 'Carla Suspendida', 'suspended'));

    await _pumpDark(
      tester,
      AdminScannerPage(
        palette: rolePalettes[GymRole.admin]!,
        state: state,
        scanInput: '',
        isLaserMoving: true,
        onScanInputChanged: (_) {},
        onTriggerVerdict: (result, member, rawInput) {},
      ),
    );

    expect(find.text('Simulación de accesos'), findsOneWidget);
    expect(find.text('DNI inválido'), findsOneWidget);
    expect(find.textContaining('(Inactivo)'), findsOneWidget);
    expect(find.textContaining('(Suspendido)'), findsOneWidget);
  });

  test('dark theme routes cards and inputs to themed surfaces', () {
    final darkTheme = AppTheme.dark();
    expect(darkTheme.cardTheme.color, SasGymColors.dark.surface);
    expect(
      darkTheme.inputDecorationTheme.fillColor,
      SasGymColors.dark.surfaceAlt,
    );
  });

  testWidgets('app boots in dark mode for every role without throwing', (
    tester,
  ) async {
    for (final role in GymRole.values) {
      final state = GymState(startBackground: false);
      addTearDown(state.dispose);
      await state.updateThemeMode(ThemeMode.dark);
      state.setCurrentGymActiveForTest(active: true);
      state.setCurrentUserForTest(_userForRole(role));

      await tester.pumpWidget(
        GymStateProvider(
          notifier: state,
          child: const SasGymApp(),
        ),
      );
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
    }
  });
}
