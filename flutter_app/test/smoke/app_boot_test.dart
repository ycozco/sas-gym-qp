import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/data/gym_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SasGymApp boots and renders login when no user is set', (tester) async {
    final state = GymState(startBackground: false);
    addTearDown(state.dispose);

    await tester.pumpWidget(
      GymStateProvider(
        notifier: state,
        child: const SasGymApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
