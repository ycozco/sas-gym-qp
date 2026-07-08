import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/data/gym_state.dart';
import 'package:flutter_app/models/gym_models.dart';
import 'package:flutter_test/flutter_test.dart';

LoggedInUser _userForRole(GymRole role) {
  return LoggedInUser(
    id: 'test-id',
    email: 'test@example.com',
    rol: role,
    nombreCompleto: 'Test User',
    estado: 'ACTIVE',
  );
}

void main() {
  for (final role in GymRole.values) {
    testWidgets('app boots for role ${role.name} without throwing', (
      tester,
    ) async {
      final state = GymState(startBackground: false);
      addTearDown(state.dispose);

      state.setCurrentGymActiveForTest(active: true);
      state.setCurrentUserForTest(_userForRole(role));

      await tester.pumpWidget(
        GymStateProvider(notifier: state, child: const SasGymApp()),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  }

  testWidgets('SaaS barrier renders when current gym is inactive', (
    tester,
  ) async {
    final state = GymState(startBackground: false);
    addTearDown(state.dispose);

    state.setCurrentGymActiveForTest(active: false);
    state.setCurrentUserForTest(_userForRole(GymRole.admin));

    await tester.pumpWidget(
      GymStateProvider(notifier: state, child: const SasGymApp()),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
