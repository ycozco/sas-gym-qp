import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/saas/gym_suspended_barrier.dart';
import 'package:flutter_app/features/member/widgets/qr_pattern.dart';
import 'package:flutter_app/features/member/widgets/timer_ring.dart';
import 'package:flutter_app/widgets/exercise_anim.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _mount(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('QRPattern monta con seed sin lanzar', (tester) async {
    await _mount(tester, const QRPattern(seed: 'test-seed-123'));
    expect(find.byType(QRPattern), findsOneWidget);
  });

  testWidgets('TimerRing monta con valores arbitrarios sin lanzar', (
    tester,
  ) async {
    await _mount(
      tester,
      const TimerRing(secondsRemaining: 12, totalSeconds: 30),
    );
    expect(find.byType(TimerRing), findsOneWidget);
  });

  testWidgets('ExerciseAnim monta para bicep curl sin lanzar', (tester) async {
    await _mount(tester, const ExerciseAnim(exerciseName: 'Curl biceps'));
    expect(find.byType(ExerciseAnim), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('GymSuspendedBarrier monta y muestra titulo de suspension', (
    tester,
  ) async {
    await _mount(tester, GymSuspendedBarrier(onContactAdmin: () {}));
    expect(find.text('SERVICIO SUSPENDIDO'), findsOneWidget);
  });
}
