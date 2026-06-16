import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../core/network/api_client.dart';
import '../core/services/sync_queue_service.dart';

class ActiveRoutineNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  ActiveRoutineNotifier({Dio? dio})
    : _dio = dio ?? ApiClient().dio,
      super(const AsyncValue.loading());

  final Dio _dio;

  /// Carga la rutina activa del miembro desde servidor o caché local.
  Future<Map<String, dynamic>?> loadActiveRoutine({
    required bool isOnline,
    required bool isBackendMode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final box = Hive.box('gym_cache');

      if (isBackendMode && isOnline) {
        try {
          final response = await _dio.get('/routines/active');
          if (response.data != null) {
            final data = Map<String, dynamic>.from(response.data as Map);
            await box.put('active_routine', data);
            state = AsyncValue.data(data);
            return data;
          }
        } catch (e) {
          // Si falla la API de red, permitimos que caiga al fallback de caché
        }
      }

      // Fallback a Hive local
      final cached = box.get('active_routine');
      if (cached != null && cached is Map) {
        final data = Map<String, dynamic>.from(cached);
        state = AsyncValue.data(data);
        return data;
      }

      state = const AsyncValue.data(null);
      return null;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Registra una sesión de entrenamiento de forma online u offline.
  Future<bool> saveWorkoutSession(
    Map<String, dynamic> session, {
    required bool isOnline,
    required bool isBackendMode,
  }) async {
    final syncPayload = _withIdempotency(session);
    if (isBackendMode) {
      if (isOnline) {
        try {
          await _dio.post(
            '/members/workout-log',
            data: syncPayload,
            options: Options(
              headers: {
                'X-Idempotency-Key': syncPayload['idempotencyKey'].toString(),
              },
            ),
          );
          return true;
        } catch (e) {
          // Error en red, guardar en cola offline
        }
      }

      await SyncQueueService.enqueue(
        '/members/workout-log',
        'POST',
        syncPayload,
        description: 'Sesión de entrenamiento offline',
        idempotencyKey: syncPayload['idempotencyKey'].toString(),
      );
      return false;
    }
    // Modo demo
    return true;
  }

  Map<String, dynamic> _withIdempotency(Map<String, dynamic> session) {
    final copy = Map<String, dynamic>.from(session);
    final existing = copy['idempotencyKey']?.toString();
    if (existing != null && existing.isNotEmpty) {
      return copy;
    }
    final seed =
        copy['sessionId'] ??
        copy['routineId'] ??
        copy['templateId'] ??
        DateTime.now().microsecondsSinceEpoch;
    copy['idempotencyKey'] = 'workout-$seed';
    return copy;
  }
}

// Proveedor de estado de la rutina activa
final activeRoutineProvider =
    StateNotifierProvider<
      ActiveRoutineNotifier,
      AsyncValue<Map<String, dynamic>?>
    >((ref) {
      return ActiveRoutineNotifier();
    });
