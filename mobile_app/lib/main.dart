// Bootstrap puro: inicializa servicios (Hive), instancia el state
// global y entrega el control a `SasGymApp`. No debe conocer
// pantallas concretas — eso vive en `app.dart` y las features.
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'data/gym_state.dart';
import 'core/services/sync_queue_service.dart';
import 'core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final hiveKey = await SecureStorage.getHiveEncryptionKey();
  try {
    await Hive.openBox('gym_cache', encryptionCipher: HiveAesCipher(hiveKey));
  } catch (e) {
    if (AppConfig.isProduction) rethrow;
    AppLogger.debug('Encrypted gym_cache unavailable, opening dev fallback', e);
    await Hive.openBox('gym_cache');
  }
  await SyncQueueService.init();
  runApp(
    GymStateProvider(
      notifier: GymState(),
      child: const SasGymApp(),
    ),
  );
}
