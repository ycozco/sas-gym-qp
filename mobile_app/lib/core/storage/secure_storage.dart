import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'jwt_token';
  static const _keyTenantId = 'tenant_id';
  static const _keyHiveEncryption = 'hive_encryption_key';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> saveTenantId(String tenantId) async {
    await _storage.write(key: _keyTenantId, value: tenantId);
  }

  static Future<String?> getTenantId() async {
    return await _storage.read(key: _keyTenantId);
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyTenantId);
  }

  static Future<List<int>> getHiveEncryptionKey() async {
    final existing = await _storage.read(key: _keyHiveEncryption);
    if (existing != null) {
      return base64Url.decode(existing);
    }

    final secureRandom = Random.secure();
    final key = List<int>.generate(32, (_) => secureRandom.nextInt(256));
    await _storage.write(key: _keyHiveEncryption, value: base64Url.encode(key));
    return key;
  }
}
