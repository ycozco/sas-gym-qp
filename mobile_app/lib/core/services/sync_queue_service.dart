import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../network/api_client.dart';

class SyncQueueService {
  static const String _boxName = 'sync_queue_box';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static Box _getBox() {
    return Hive.box(_boxName);
  }

  // Encolar una transacción offline
  static Future<void> enqueue(String endpoint, String method, Map<String, dynamic> data, {String? description}) async {
    final box = _getBox();
    final queue = List<Map<dynamic, dynamic>>.from(box.get('queue', defaultValue: []));
    
    queue.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'endpoint': endpoint,
      'method': method,
      'data': data,
      'description': description ?? 'Transacción offline encolada',
      'timestamp': DateTime.now().toIso8601String(),
    });

    await box.put('queue', queue);
    debugPrint('Transacción encolada en SyncQueue: $endpoint - $description');
  }

  // Obtener todos los items en la cola
  static List<Map<String, dynamic>> getQueue() {
    final box = _getBox();
    final raw = box.get('queue', defaultValue: []);
    return List<Map<String, dynamic>>.from(
      raw.map((item) => Map<String, dynamic>.from(item as Map)),
    );
  }

  // Limpiar la cola
  static Future<void> clearQueue() async {
    final box = _getBox();
    await box.put('queue', []);
  }

  // Intentar procesar y sincronizar la cola
  static Future<bool> processQueue() async {
    final queue = getQueue();
    if (queue.isEmpty) return true;

    debugPrint('Procesando cola de sincronización offline: ${queue.length} pendientes...');
    final List<Map<String, dynamic>> remaining = [];
    bool allSucceeded = true;

    for (var tx in queue) {
      final String endpoint = tx['endpoint'];
      final String method = tx['method'];
      final Map<String, dynamic> data = tx['data'];
      final String id = tx['id'];

      try {
        if (method.toUpperCase() == 'POST') {
          await ApiClient().dio.post(endpoint, data: data);
        } else if (method.toUpperCase() == 'PUT') {
          await ApiClient().dio.put(endpoint, data: data);
        } else if (method.toUpperCase() == 'DELETE') {
          await ApiClient().dio.delete(endpoint, data: data);
        }
        debugPrint('Sincronización exitosa para tx: $id ($endpoint)');
      } catch (e) {
        debugPrint('Fallo al sincronizar tx $id ($endpoint): $e. Re-encolando.');
        remaining.add(tx);
        allSucceeded = false;
      }
    }

    final box = _getBox();
    await box.put('queue', remaining);
    return allSucceeded;
  }
}
