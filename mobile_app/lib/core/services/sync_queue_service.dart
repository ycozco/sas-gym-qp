import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/encrypted_hive.dart';

class SyncQueueService {
  static const String _boxName = 'sync_queue_box';
  static const int maxAttempts = 3;
  static const Duration defaultTtl = Duration(days: 2);

  static Future<void> init() async {
    await EncryptedHive.openBox(_boxName);
  }

  static Box _getBox() {
    return Hive.box(_boxName);
  }

  static Future<void> enqueue(
    String endpoint,
    String method,
    Map<String, dynamic> data, {
    String? description,
    String? idempotencyKey,
    bool financial = false,
    Duration ttl = defaultTtl,
  }) async {
    if (financial && (idempotencyKey == null || idempotencyKey.isEmpty)) {
      throw ArgumentError('Financial offline operations require an idempotencyKey.');
    }

    final box = _getBox();
    final queue = List<Map<dynamic, dynamic>>.from(box.get('queue', defaultValue: []));
    final now = DateTime.now();
    final txId = now.microsecondsSinceEpoch.toString();

    queue.add({
      'id': txId,
      'idempotencyKey': idempotencyKey ?? txId,
      'endpoint': endpoint,
      'method': method,
      'data': data,
      'description': description ?? 'Transaccion offline encolada',
      'timestamp': now.toIso8601String(),
      'attempts': 0,
      'lastAttemptAt': null,
      'expiresAt': now.add(ttl).toIso8601String(),
      'lastError': null,
      'financial': financial,
    });

    await box.put('queue', queue);
    AppLogger.debug('Transaccion encolada en SyncQueue: $endpoint - $description');
  }

  static List<Map<String, dynamic>> getQueue() {
    final box = _getBox();
    final raw = box.get('queue', defaultValue: []);
    return List<Map<String, dynamic>>.from(
      raw.map((item) => Map<String, dynamic>.from(item as Map)),
    );
  }

  static Future<void> clearQueue() async {
    final box = _getBox();
    await box.put('queue', []);
  }

  static Future<bool> processQueue({
    Future<void> Function(String method, String endpoint, Map<String, dynamic> data, String idempotencyKey)? sender,
    DateTime? now,
  }) async {
    final queue = getQueue();
    if (queue.isEmpty) return true;

    AppLogger.debug('Procesando cola de sincronizacion offline: ${queue.length} pendientes...');
    final List<Map<String, dynamic>> remaining = [];
    bool allSucceeded = true;
    final currentTime = now ?? DateTime.now();

    for (final tx in queue) {
      final endpoint = tx['endpoint'].toString();
      final method = tx['method'].toString();
      final data = Map<String, dynamic>.from(tx['data'] as Map);
      final id = tx['id'].toString();
      final idempotencyKey = tx['idempotencyKey']?.toString() ?? id;
      final attempts = tx['attempts'] is int ? tx['attempts'] as int : 0;
      final expiresAt = DateTime.tryParse(tx['expiresAt']?.toString() ?? '');

      if (expiresAt != null && currentTime.isAfter(expiresAt)) {
        AppLogger.debug('Transaccion offline expirada y descartada: $id ($endpoint)');
        allSucceeded = false;
        continue;
      }

      if (attempts >= maxAttempts) {
        AppLogger.debug('Transaccion offline excedio max attempts: $id ($endpoint)');
        allSucceeded = false;
        continue;
      }

      try {
        if (sender != null) {
          await sender(method, endpoint, data, idempotencyKey);
        } else {
          final options = Options(headers: {'X-Idempotency-Key': idempotencyKey});
          if (method.toUpperCase() == 'POST') {
            await ApiClient().dio.post(endpoint, data: data, options: options);
          } else if (method.toUpperCase() == 'PUT') {
            await ApiClient().dio.put(endpoint, data: data, options: options);
          } else if (method.toUpperCase() == 'DELETE') {
            await ApiClient().dio.delete(endpoint, data: data, options: options);
          }
        }
        AppLogger.debug('Sincronizacion exitosa para tx: $id ($endpoint)');
      } catch (e) {
        AppLogger.debug('Fallo al sincronizar tx $id ($endpoint). Re-encolando', e);
        tx['attempts'] = attempts + 1;
        tx['lastAttemptAt'] = currentTime.toIso8601String();
        tx['lastError'] = e.toString();
        remaining.add(tx);
        allSucceeded = false;
      }
    }

    final box = _getBox();
    await box.put('queue', remaining);
    return allSucceeded;
  }
}
