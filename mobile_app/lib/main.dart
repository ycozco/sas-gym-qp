// Bootstrap puro: inicializa servicios (Hive), instancia el state
// global y entrega el control a `SasGymApp`. No debe conocer
// pantallas concretas — eso vive en `app.dart` y las features.
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'data/gym_state.dart';
import 'core/services/sync_queue_service.dart';
import 'core/storage/encrypted_hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await EncryptedHive.openBox('gym_cache');
  await Hive.openBox('ui_settings_box');
  await SyncQueueService.init();
  runApp(GymStateProvider(notifier: GymState(), child: const SasGymApp()));
}
