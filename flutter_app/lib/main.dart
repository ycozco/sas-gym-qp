import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'data/gym_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('gym_cache');
  runApp(
    GymStateProvider(
      notifier: GymState(),
      child: const SasGymApp(),
    ),
  );
}
