import 'package:hive/hive.dart';

import '../config/app_config.dart';
import 'secure_storage.dart';

class EncryptedHive {
  static Future<Box> openBox(String name) async {
    final hiveKey = await SecureStorage.getHiveEncryptionKey();
    try {
      return await Hive.openBox(name, encryptionCipher: HiveAesCipher(hiveKey));
    } catch (e) {
      if (AppConfig.isProduction || AppConfig.environment == AppEnvironment.staging) {
        rethrow;
      }
      AppLogger.debug('Migrating legacy Hive box to encrypted storage: $name', e);
      return _migrateLegacyBox(name, hiveKey);
    }
  }

  static Future<Box> _migrateLegacyBox(String name, List<int> hiveKey) async {
    final legacyBox = await Hive.openBox(name);
    final legacyData = Map<dynamic, dynamic>.from(legacyBox.toMap());

    await legacyBox.close();
    await Hive.deleteBoxFromDisk(name);

    final encryptedBox = await Hive.openBox(
      name,
      encryptionCipher: HiveAesCipher(hiveKey),
    );
    if (legacyData.isNotEmpty) {
      await encryptedBox.putAll(legacyData);
    }
    return encryptedBox;
  }
}
