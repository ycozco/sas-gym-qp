import 'package:flutter/material.dart';
import 'app.dart';
import 'data/gym_state.dart';

void main() {
  runApp(
    GymStateProvider(
      notifier: GymState(),
      child: const SasGymApp(),
    ),
  );
}
